defmodule CodeStats.XP do
  import CodeStats.Utils.TypedSchema
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]

  deftypedschema "xps" do
    field(:amount, :integer, integer())
    belongs_to(:pulse, CodeStats.User.Pulse, CodeStats.User.Pulse.t())
    belongs_to(:language, CodeStats.Language, CodeStats.Language.t())

    # Original language can be used to fix alias errors later, it should always use
    # the language that was sent. :language field on the other hand follows aliases
    belongs_to(:original_language, CodeStats.Language, CodeStats.Language.t())

    timestamps(type: :utc_datetime)
  end

  @doc """
  Creates a changeset based on the `data` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(data, params \\ %{}) do
    data
    |> cast(params, [:amount])
    |> validate_required([:amount])
  end

  @doc """
  Get all of a user's XP's by user ID.
  """
  @spec xps_by_user_id(integer) :: Ecto.Query.t()
  def xps_by_user_id(user_id) when is_integer(user_id) do
    from(
      x in __MODULE__,
      join: p in CodeStats.User.Pulse,
      on: p.id == x.pulse_id,
      where: p.user_id == ^user_id,
      preload: [:language, pulse: {p, :machine}]
    )
  end
end
