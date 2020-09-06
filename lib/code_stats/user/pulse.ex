defmodule CodeStats.User.Pulse do
  import CodeStats.Utils.TypedSchema
  import Ecto.Changeset

  deftypedschema "pulses" do
    # When the Pulse was generated on the client. This is somewhat confusingly named
    # "sent_at" for legacy reasons, better name would be "coded_at".
    field(:sent_at, :utc_datetime, DateTime.t())

    # Same value as before, but stored in the client's local timezone offset. This should
    # be used for certain aggregations to make the results more useful for the user.
    field(:sent_at_local, :naive_datetime, NaiveDateTime.t())

    # Original offset from UTC for the sent_at_local timestamp. In minutes.
    field(:tz_offset, :integer, pos_integer())
    belongs_to(:user, CodeStats.User, CodeStats.User.t())
    belongs_to(:machine, CodeStats.User.Machine, CodeStats.User.Machine.t())

    has_many(:xps, CodeStats.XP, [CodeStats.XP.t()])

    timestamps(type: :utc_datetime)
  end

  @doc """
  Creates a changeset based on the `data` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(data, params \\ %{}) do
    data
    |> cast(params, [:sent_at, :sent_at_local, :tz_offset])
    |> validate_required([:sent_at, :sent_at_local, :tz_offset])
  end
end
