defmodule CodeStats.User.Machine do
  import CodeStats.Utils.TypedSchema
  import Ecto.Changeset

  deftypedschema "machines" do
    field(:name, :string, String.t())
    field(:api_salt, :string, String.t())
    field(:active, :boolean, boolean())

    belongs_to(:user, CodeStats.User, CodeStats.User.t())
    has_many(:pulses, CodeStats.User.Pulse, [CodeStats.User.Pulse.t()])

    timestamps(type: :utc_datetime)
  end

  @doc """
  Maximum length of machine's name.
  """
  def machine_name_max_length(), do: 64

  @doc """
  Creates a changeset based on the `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  @spec create_changeset(map()) :: Ecto.Changeset.t()
  def create_changeset(params \\ %{}) do
    %__MODULE__{}
    |> cast(params, [:name])
    |> validate_required([:name])
    |> name_validations()
    |> put_assoc(:user, Map.get(params, :user))
    |> foreign_key_constraint(:user_id)
    |> put_change(:api_salt, generate_api_salt())
    |> validate_length(:api_salt, min: 1, max: 255)
    |> put_change(:active, true)
  end

  @spec update_changeset(t(), map()) :: Ecto.Changeset.t()
  def update_changeset(data, params \\ %{}) do
    data
    |> cast(params, [:name])
    |> validate_required([:name])
    |> name_validations()
  end

  @spec activation_changeset(t(), map()) :: Ecto.Changeset.t()
  def activation_changeset(data, params \\ %{}) do
    data
    |> cast(params, [:active])
  end

  @doc """
  Creates a changeset to regenerate the API salt of the Machine.

  Takes no input.
  """
  @spec activation_changeset(t()) :: Ecto.Changeset.t()
  def api_changeset(data) do
    data
    |> change(%{api_salt: generate_api_salt()})
  end

  defp name_validations(changeset) do
    changeset
    |> validate_required([:name])
    |> validate_length(:name, min: 1, max: machine_name_max_length())
    |> unique_constraint(:name, name: :machines_name_user_id_index)
  end

  defp generate_api_salt() do
    Bcrypt.gen_salt(Application.get_env(:comeonin, :bcrypt_log_rounds))
  end
end
