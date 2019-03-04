defmodule CodeStatsWeb.FrontpageChannel do
  use Phoenix.Channel

  @moduledoc """
  The frontpage channel is used to send live updates of total
  XP numbers on the front page.
  """

  def join("frontpage", _params, socket) do
    history_data =
      CodeStats.XPHistoryCache.get_data()
      |> Enum.map(fn {{{y, mo, d}, {h, min}}, xp} -> [[[y, mo, d], [h, min]], xp] end)

    data = %{
      xp_history: history_data
    }

    {:ok, data, socket}
  end

  @doc """
  API to send new pulse to channel.
  """
  @spec send_pulse(map, [%{language: String.t(), amount: integer}]) :: :ok
  def send_pulse(coords, xps) when is_list(xps) do
    CodeStatsWeb.Endpoint.broadcast("frontpage", "new_pulse", %{
      xps: xps,
      coords: coords
    })

    :ok
  end
end
