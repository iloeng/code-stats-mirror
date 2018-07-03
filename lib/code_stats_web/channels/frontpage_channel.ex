defmodule CodeStatsWeb.FrontpageChannel do
  use Phoenix.Channel

  @moduledoc """
  The frontpage channel is used to send live updates of total
  XP numbers on the front page.
  """

  alias CodeStats.User.Pulse

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

  The given pulse must have xps preloaded, xps must have language preloaded.
  """
  @spec send_pulse(map, %Pulse{}) :: :ok
  def send_pulse(coords, %Pulse{xps: xps})
      when not is_nil(xps) do
    formatted_xps =
      for xp <- xps do
        %{
          xp: xp.amount,
          language: xp.language.name
        }
      end

    CodeStatsWeb.Endpoint.broadcast("frontpage", "new_pulse", %{
      xps: formatted_xps,
      coords: coords
    })
  end
end
