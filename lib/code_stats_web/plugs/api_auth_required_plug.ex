defmodule CodeStatsWeb.MachineAuthRequiredPlug do
  @moduledoc """
  This plug requires the user to be authenticated with a machine API token.

  If the user is not authenticated, an error code will be returned.
  """

  @machine_auth_header "x-api-token"

  import Plug.Conn
  alias Plug.Conn

  alias CodeStatsWeb.AuthUtils

  def init(opts) do
    opts
  end

  def call(conn, _opts) do
    ret =
      with [auth_header] <- get_req_header(conn, @machine_auth_header),
           %Conn{} = conn <- AuthUtils.auth_machine(conn, auth_header),
           true <- AuthUtils.is_machine_authed?(conn) do
        conn
      end

    case ret do
      %Conn{} = conn ->
        conn

      _ ->
        conn
        |> send_resp(403, ~S({"error": "You must be authenticated"}))
        |> halt()
    end
  end
end
