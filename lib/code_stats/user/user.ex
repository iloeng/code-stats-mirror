defmodule CodeStats.User do
  require Logger

  import CodeStats.Utils.TypedSchema
  import Ecto.Changeset
  import Ecto.Query

  alias CodeStats.Repo
  alias CodeStats.User.{Pulse, Alias}

  deftypedschema "users" do
    field(:username, :string, String.t())
    field(:email, :string, String.t())
    field(:password, :string, String.t())
    field(:last_cached, :utc_datetime, DateTime.t())
    field(:private_profile, :boolean, boolean())
    field(:cache, :map, CodeStats.User.Cache.db_t())

    # The latest version of the legal terms that was accepted by the user
    field(:terms_version, :date, Date.t())

    # Email address used for Gravatar, or nil
    field(:gravatar_email, :string, String.t())

    has_many(:pulses, Pulse, [Pulse.t()])

    timestamps(type: :utc_datetime)
  end

  @doc """
  Get a changeset based on the `data` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(data, params \\ %{}) do
    data
    |> cast(params, [:username, :password, :email, :terms_version])
    |> validate_required([:username, :password, :terms_version])
    |> put_change(:private_profile, false)
    |> validate_length(:username, min: 1, max: 64)
    |> validate_format(:username, ~r/^[^\/#%?&=+]+$/)
    |> validate_latest_terms()
    |> password_validations()
    |> common_validations()
    |> unique_constraint(:username)
    |> unique_constraint(:lower_username)
    |> update_change(:password, &hash_password/1)
  end

  @doc """
  Get changeset for updating a user's data.
  """
  def updating_changeset(data, params \\ %{}) do
    data
    |> cast(params, [:email, :gravatar_email, :private_profile])
    |> common_validations()
  end

  @doc """
  Get a changeset for changing a user's password.
  """
  def password_changeset(data, params \\ %{}) do
    data
    |> cast(params, [:password])
    |> validate_required([:password])
    |> password_validations()
    |> update_change(:password, &hash_password/1)
  end

  @doc """
  Get a changeset for updating user's latest accepted legal terms.
  """
  @spec terms_changeset(map, map) :: Ecto.Changeset.t()
  def terms_changeset(data, params \\ %{}) do
    data
    |> cast(params, [:terms_version])
    |> validate_required([:terms_version])
    |> validate_latest_terms()
  end

  @doc """
  Get all users in the system that have an email address. Returned as a list of tuples where the
  first element is the username and the second element is the email address.
  """
  @spec get_all_with_email() :: [{String.t(), String.t()}]
  def get_all_with_email() do
    from(
      u in __MODULE__,
      where: not is_nil(u.email) and u.email != "",
      select: {u.username, u.email}
    )
    |> Repo.all()
  end

  @doc """
  Update user's accepted legal terms version to the latest available.
  """
  @spec update_terms_version(t()) :: :ok | {:error, [{atom, Ecto.Changeset.error()}]}
  def update_terms_version(%__MODULE__{} = user) do
    cset = terms_changeset(user, %{terms_version: CodeStats.LegalTerms.get_latest_version()})

    case Repo.update(cset) do
      {:ok, _} -> :ok
      {:error, %Ecto.Changeset{} = err_cset} -> {:error, err_cset.errors}
    end
  end

  @doc """
  Get user with the given username.

  If second argument is true, case insensitive search is used instead.

  Returns nil if user was not found.
  """
  @spec get_by_username(String.t(), boolean()) :: t() | nil
  def get_by_username(username, case_insensitive \\ false) do
    query =
      case case_insensitive do
        false ->
          from(u in __MODULE__, where: u.username == ^username)

        true ->
          from(
            u in __MODULE__,
            where: fragment("lower(?)", ^username) == fragment("lower(?)", u.username)
          )
      end

    Repo.one(query)
  end

  defp hash_password(password) do
    Bcrypt.hash_pwd_salt(password)
  end

  # Common validations for creating and editing users
  defp common_validations(changeset) do
    changeset
    |> validate_length(:email, min: 3, max: 255)
    |> validate_format(:email, ~r/^$|^.+@.+$/)
    |> validate_length(:gravatar_email, min: 3, max: 255)
    |> validate_format(:gravatar_email, ~r/^$|^.+@.+$/)
  end

  defp password_validations(changeset) do
    changeset
    |> validate_length(:password, min: 6, max: 255)
  end

  # Validate that the accepted terms version is the latest one, user cannot accept older
  # terms
  defp validate_latest_terms(changeset) do
    validate_change(changeset, :terms_version, fn
      _, %Date{} = d ->
        if CodeStats.LegalTerms.is_current_version?(d) do
          []
        else
          Logger.error("Invalid legal terms version #{inspect(d)}.")
          ["Invalid legal terms version."]
        end

      _, val ->
        Logger.error("Invalid legal terms type #{inspect(val)}.")
        ["Error setting legal terms acceptance."]
    end)
  end
end
