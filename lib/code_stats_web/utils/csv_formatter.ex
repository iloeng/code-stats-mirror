defmodule CodeStatsWeb.Utils.CsvFormatter do

  alias CodeStats.User.Pulse

  @doc """
  Returns a semi-colon separated values

  pulses = [%Pulse{sent_at: sent_at, sent_at_local: sent_at_local, tz_offset: tz_offset, machine: machine, xps: xps}]
  """
  def format([], headers), do: Enum.join(headers, ";") <> "\n"

  def format(pulses, headers) do
    pulses
    |> Enum.map(&to_list(&1))
    |> prepend(headers)
    |> CSV.encode(separator: ?;, delimiter: "\n")
    |> Enum.to_list()
    |> to_string()
  end

  defp to_list(%Pulse{sent_at: sent_at, sent_at_local: sent_at_local, tz_offset: tz_offset, machine: machine, xps: xps}) do
    [
      "#{sent_at}",
      "#{sent_at_local}",
      "#{tz_offset}",
      xps |> Enum.map(fn xp -> xp.language.name end) |> Enum.uniq() |> Enum.join(","),
      machine.name,
      Enum.reduce(xps, 0, fn xp, acc -> acc + xp.amount end)
    ]
  end

  defp prepend(list, headers), do: [headers | list]
end
