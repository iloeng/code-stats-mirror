defmodule CodeStats.XP.XPCacheRefresher do
  @moduledoc """
  This module handles refreshing the caches of all users periodically. This is done to avoid
  accumulating problems that might happen with miscalculations of cached user data.
  """
  use GenServer

  import Ecto.Query, only: [from: 2]

  alias CodeStats.{Repo, User}

  # Run every 24 hours
  @how_often 24 * 60 * 60 * 1000

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
  Refresh XP caches of all users in the system.
  """
  @spec do_refresh() :: :ok
  def do_refresh() do
    from(u in User, select: u)
    |> Repo.all()
    |> Enum.each(fn user -> User.update_cached_xps(user, true) end)
  end
end
