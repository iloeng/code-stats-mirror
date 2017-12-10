defmodule CodeStats.XPHistoryCache do
  @moduledoc """
  XP history cache stores the received XP amounts in the last n hours.
  """

  import Ecto.Query, only: [from: 2]

  alias CodeStats.{
    Repo,
    XP,
    Pulse
  }

  # How many hours to store
  @history_hours 12

  # ETS table name
  @table :xp_history_cache

  # How often to do a total refresh, in seconds
  @refresh_after 1800

  def start_link() do
    GenServer.start_link(__MODULE__, %{})
  end

  def init(state) do
    :ets.new(@table, [
      :named_table,
      :set,
      :public,
      read_concurrency: true,
      write_concurrency: true
    ])

    refresh_cache_and_repeat()

    {:ok, state}
  end

  def handle_info(:refresh, state) do
    refresh_cache_and_repeat()
    {:noreply, state}
  end

  def refresh_cache_and_repeat() do
    refresh_cache()
    Process.send_after(self(), :refresh, @refresh_after)
  end

  @doc """
  Refresh XP history cache.
  """
  def refresh_cache() do
  end
end
