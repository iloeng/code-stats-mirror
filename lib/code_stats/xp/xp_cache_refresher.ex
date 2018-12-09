defmodule CodeStats.XP.XPCacheRefresher do
  @moduledoc """
  This module handles refreshing the caches of all users periodically. This is done to avoid
  accumulating problems that might happen with miscalculations of cached user data.
  """
  use GenServer

  import Ecto.Query, only: [from: 2]

  alias CodeStats.{Repo, User}

  # Run about every second minute (120 seconds after last run)
  @how_often 2 * 60 * 1000

  # How many seconds back to fetch data for the "last 24h sync"
  @sync_24h_secs 24 * 60 * 60

  # How many users to sync for the "last 24h sync"
  @sync_24h_count 50

  # How many users to sync totally
  @sync_total_count 1

  def start_link do
    GenServer.start_link(__MODULE__, %{})
  end

  def init(state) do
    do_refresh()

    Process.send_after(self(), :work, @how_often)
    {:ok, state}
  end

  def handle_info(:work, state) do
    do_refresh()

    # Start the timer again
    Process.send_after(self(), :work, @how_often)

    {:noreply, state}
  end

  @doc """
  Refresh XP caches users in the system.

  Will pick a bunch of the users that have not been synced in the last 24 hours (least recently
  synced first), and sync their data from the last 24 hours. For this sync, if the user does not
  have any pulses added after the last cache time, they are not synced.

  After that, pick a smaller list of users (least recently synced first) and sync them totally.
  """
  @spec do_refresh() :: :ok
  def do_refresh() do
    sync_24h()
    sync_total()
  end

  defp sync_24h() do
    now = DateTime.utc_now()
    then = Calendar.DateTime.subtract!(now, @sync_24h_secs)

    from(u in User,
      join: p in User.Pulse,
      on: p.user_id == u.id,
      where: u.last_cached < ^then and p.inserted_at > ^then,
      group_by: u.id,
      having: count(p) > 0,
      order_by: [asc: u.last_cached],
      limit: @sync_24h_count
    )
    |> Repo.all()
    |> Enum.each(&User.update_cached_xps(&1, then))
  end

  defp sync_total() do
    from(u in User, order_by: [asc: u.last_cached], limit: @sync_total_count)
    |> Repo.all()
    |> Enum.each(&User.update_cached_xps(&1, :all))
  end
end
