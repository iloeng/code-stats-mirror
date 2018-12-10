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
  Refresh XP caches of a number of users in the system. The least recently cached users are picked
  first.
  """
  @spec do_refresh() :: :ok
  def do_refresh() do
    from(u in User, order_by: [asc: u.last_cached], limit: @sync_total_count)
    |> Repo.all()
    |> Enum.each(&User.update_cached_xps(&1, true))
  end
end
