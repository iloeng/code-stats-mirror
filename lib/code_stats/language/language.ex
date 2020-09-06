defmodule CodeStats.Language do
  import CodeStats.Utils.TypedSchema
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]

  # Default language name if given language name is invalid
  @default_name "Plain text"

  deftypedschema "languages" do
    field(:name, :string, String.t())

    has_many(:xps, CodeStats.XP, [CodeStats.XP.t()])

    # Either a language has many aliases or it is an alias of some other language,
    # it cannot be both.
    # NOTE: Only 1 level of aliases is supported! That is, you cannot form a chain of
    # aliases.
    belongs_to(:alias_of, __MODULE__, __MODULE__.t() | nil)
    has_many(:aliases, __MODULE__, [__MODULE__.t()], foreign_key: :alias_of_id)

    timestamps(type: :utc_datetime)
  end

  @doc """
  Creates a changeset based on the `data` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(data, params \\ %{}) do
    data
    |> cast(params, [:name])
    |> validate_required([:name])
    |> validate_length(:name, min: 1, max: 255)
    |> unique_constraint(:name)
    |> unique_constraint(:lower_name)
  end

  @doc """
  Get or create language with the given name using the given repo.
  """
  @spec get_or_create(Ecto.Repo.t() | nil, String.t()) ::
          {:ok, t()} | {:error, :unknown}
  def get_or_create(repo \\ CodeStats.Repo, language_name) do
    language_name = sanitize_language(language_name)

    # Get-create-get to handle race conditions
    get_query =
      from(
        l in __MODULE__,
        where: fragment("lower(?)", l.name) == fragment("lower(?)", ^language_name),
        preload: :alias_of
      )

    create_cset =
      changeset(%__MODULE__{}, %{"name" => language_name})
      |> put_assoc(:alias_of, nil)

    with nil <- repo.one(get_query),
         {:error, _} <- repo.insert(create_cset),
         nil <- repo.one(get_query) do
      {:error, :unknown}
    else
      %__MODULE__{} = language -> {:ok, language}
      {:ok, language} -> {:ok, language}
    end
  end

  # Sanitize language name to what makes sense in the system by trimming whitespace and converting
  # empty name to default name
  defp sanitize_language(name) when is_binary(name) do
    case String.trim(name) do
      "" -> @default_name
      name -> name
    end
  end
end
