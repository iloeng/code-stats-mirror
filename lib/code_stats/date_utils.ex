defmodule CodeStats.DateUtils do
  @moduledoc """
  This module contains utilities related to date and time handling.
  """

  @doc ~S"""
  Convert the given UTC datetime and an offset into a naive local datetime, reconstructing the
  user's local time.

  ## Examples

      iex> {:ok, dt, _} = DateTime.from_iso8601("2019-01-15T15:00:00Z");
      ...> CodeStats.DateUtils.utc_and_offset_to_local(dt, 120)
      ~N[2019-01-15T17:00:00]
  """
  @spec utc_and_offset_to_local(DateTime.t(), integer()) :: NaiveDateTime.t()
  def utc_and_offset_to_local(%DateTime{} = date, offset) when is_integer(offset) do
    Calendar.DateTime.add!(date, offset * 60) |> Calendar.DateTime.to_naive()
  end
end
