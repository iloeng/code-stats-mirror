defmodule CodeStats.XP do
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]

  schema "xps" do
    field(:amount, :integer)
    belongs_to(:pulse, CodeStats.User.Pulse)
    belongs_to(:language, CodeStats.Language)

    # Original language can be used to fix alias errors later, it should always use
    # the language that was sent. :language field on the other hand follows aliases
    belongs_to(:original_language, CodeStats.Language)

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
  @spec xps_by_user_id(integer) :: %Ecto.Query{}
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
