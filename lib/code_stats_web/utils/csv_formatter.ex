defmodule CodeStatsWeb.Utils.CsvFormatter do
  alias CodeStats.XP
  alias CodeStats.Language
  alias CodeStats.User.Pulse
  alias CodeStats.User.Machine

  @doc """
  Returns the given list of XPs as CSV formatted text.
  """
  @spec format([%XP{}], [String.t()]) :: String.t()
  def format([], headers), do: Enum.join(headers, ";") <> "\n"

  def format(xps, headers) do
    xps
    |> Enum.map(&to_list(&1))
    |> prepend(headers)
    |> CSV.encode(separator: ?;, delimiter: "\n")
    |> Enum.to_list()
    |> to_string()
  end

  defp to_list(%XP{
         pulse: %Pulse{
           sent_at: sent_at,
           sent_at_local: sent_at_local,
           tz_offset: tz_offset,
           machine: %Machine{name: machine}
         },
         language: %Language{name: language},
         amount: xp
       }) do
    [
      "#{sent_at}",
      "#{sent_at_local}",
      "#{tz_offset}",
      language,
      machine,
      xp
    ]
  end

  defp prepend(list, headers), do: [headers | list]
end
