defmodule CodeStatsWeb.ProfileChannel do
  use Phoenix.Channel

  alias CodeStats.User
  alias CodeStats.User.Pulse

  @moduledoc """
  The profile channel is used to broadcast information about a certain user's
  profile when it is updated.
  """

  def join("users:" <> username, _params, socket) do
    # Profile channel can be accessed if:
    # The profile is public, OR
    # the current user is the same as the profile user.

    with %User{} = user <- User.get_by_username(username),
         true <- !user.private_profile or socket.assigns[:user_id] === user.id do
      {:ok, %{}, socket}
    else
      _ -> {:error, %{reason: "Unauthorized."}}
    end
  end

  #  def handle_out("new_pulse", payload, socket) do
  #    push(socket, "new_pulse", payload)
  #    {:noreply, socket}
  #  end

  @doc """
  API to send new pulse to channel.

  Chooses the correct user channel based on the user. The given pulse must have
  xps and machine preloaded, xps themselves must have language preloaded.
  """
  def send_pulse(%User{} = user, %Pulse{
        xps: xps,
        machine: machine,
        sent_at_local: sent_at_local,
        tz_offset: tz_offset,
        sent_at: sent_at
      })
      when not is_nil(xps) and not is_nil(machine) do
    formatted_xps =
      for xp <- xps do
        %{
          amount: xp.amount,
          language: xp.language.name
        }
      end

    CodeStatsWeb.Endpoint.broadcast("users:#{user.username}", "new_pulse", %{
      xps: formatted_xps,
      sent_at_local: recreate_iso8601_with_offset(sent_at_local, tz_offset),
      sent_at: DateTime.to_iso8601(sent_at),
      machine: machine.name
    })
  end

  # Return ISO 8601 formatted timestamp with offset recreated from the data stored in the DB.
  # There's no way to create an actual struct with the date libraries in use, so just add the
  # offset as hours and minutes after the formatted datetime string.
  defp recreate_iso8601_with_offset(%NaiveDateTime{} = ndt, offset) when is_integer(offset) do
    dt_str = NaiveDateTime.to_iso8601(ndt)
    tz_h = (offset / 60) |> trunc()
    tz_h_str = tz_h |> abs() |> Integer.to_string() |> String.pad_leading(2, "0")
    tz_m_str = (offset - tz_h * 60) |> abs() |> Integer.to_string() |> String.pad_leading(2, "0")
    sign_str = if tz_h < 0, do: "-", else: "+"
    "#{dt_str}#{sign_str}#{tz_h_str}:#{tz_m_str}"
  end
end
