defmodule CodeStats.XPHistoryCache do
  @moduledoc """
  XP history cache stores the received XP amounts in the last n hours, grouped to blocks of m minutes.
  """

  import Ecto.Query, only: [from: 2]
  import Ex2ms, only: [fun: 1]

  alias CodeStats.{
    Repo,
    XP
  }

  alias CodeStats.User.Pulse

  # How many hours to store (maximum is 24 hours as older stale data is deleted)
  @history_hours 4

  # Group data into blocks of this many minutes. Use 1 to disable. This must divide 60 minutes evenly.
  @group_minutes 1

  # ETS table name
  @table :xp_history_cache

  # How often to refresh data, in seconds. This will be run often enough to not need live updates from
  # controllers, which simplifies the code.
  @refresh_after 10

  def start_link() do
    GenServer.start_link(__MODULE__, nil)
  end

  def init(state) do
    init_table()
    refresh_cache_and_repeat()

    {:ok, state}
  end

  def handle_info(:refresh, state) do
    refresh_cache_and_repeat()
    {:noreply, state}
  end

  @doc """
  Initialize the table.
  """
  def init_table() do
    :ets.new(@table, [
      :named_table,
      :ordered_set,
      :protected,
      read_concurrency: true
    ])
  end

  @doc """
  Refresh the cache and time a new refresh to be executed after the set refresh_after.
  """
  def refresh_cache_and_repeat() do
    refresh_cache()
    Process.send_after(self(), :refresh, 1000 * @refresh_after)
  end

  @doc """
  Refresh XP history cache.
  """
  def refresh_cache() do
    now = DateTime.utc_now()
    since = Calendar.DateTime.subtract!(now, 3600 * @history_hours)

    data =
      from(
        x in XP,
        join: p in Pulse,
        on: x.pulse_id == p.id,
        where: p.sent_at > ^since,
        select: {
          {
            {
              fragment("extract('year' from ?)::int as year", p.sent_at),
              fragment("extract('month' from ?)::int as month", p.sent_at),
              fragment("extract('day' from ?)::int as day", p.sent_at)
            },
            {
              fragment("extract('hour' from ?)::int as hour", p.sent_at),
              fragment(
                "extract('minute' from ?)::int / ? * ? as minute",
                p.sent_at,
                @group_minutes,
                @group_minutes
              )
            }
          },
          sum(x.amount)
        },
        group_by: [
          fragment("year"),
          fragment("month"),
          fragment("day"),
          fragment("hour"),
          fragment("minute")
        ],
        order_by: [
          desc: fragment("year"),
          desc: fragment("month"),
          desc: fragment("day"),
          desc: fragment("hour"),
          desc: fragment("minute")
        ]
      )
      |> Repo.all()

    :ets.insert(@table, data)
    clear_old()
  end

  @doc """
  Clear old, stale data from the cache table.
  """
  def clear_old() do
    ms = delete_ms()
    :ets.select_delete(@table, ms)
  end

  @doc """
  Read data from cache.
  """
  def get_data() do
    :ets.select_reverse(@table, [{:"$1", [], [:"$$"]}])
    |> Enum.map(fn [item] -> item end)
  end

  # Get match spec for deleting old items from cache
  defp delete_ms() do
    now = Date.utc_today()
    yesterday = Date.add(now, -1)
    {ny, nm, nd} = Date.to_erl(now)
    {yy, ym, yd} = Date.to_erl(yesterday)

    fun do
      {{{ky, km, kd}, _}, _}
      when not ((ky == ^ny and km == ^nm and kd == ^nd) or (ky == ^yy and km == ^ym and kd == ^yd)) ->
        true
    end
  end
end
