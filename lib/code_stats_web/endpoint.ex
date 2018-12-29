defmodule CodeStatsWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :code_stats

  socket("/live_update_socket", CodeStatsWeb.LiveUpdateSocket, websocket: true)

  plug(CodeStatsWeb.RequestTimePlug)

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phoenix.digest
  # when deploying your static files in production.
  plug(
    Plug.Static,
    at: "/",
    from: :code_stats,
    gzip: true,
    only: ~w(assets js css favicon.ico robots.txt)
  )

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket("/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket)
    plug(Phoenix.LiveReloader)
    plug(Phoenix.CodeReloader)
  end

  plug(RemoteIp)

  plug(Plug.RequestId)
  plug(Plug.Logger)

  plug(
    Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Jason
  )

  plug(Plug.MethodOverride)

  plug(CodeStatsWeb.CORS)

  plug(Plug.Head)

  plug(
    Plug.Session,
    store: :cookie,
    key: "_code_stats_key",
    signing_salt: "UuJXllxk"
  )

  use Appsignal.Phoenix
  plug(CodeStatsWeb.Router)

  def init(_key, config) do
    if config[:load_from_system_env] do
      port = get_env("PORT", :int)
      host = get_env("HOST", :str)
      host_port = get_env("HOST_PORT", :int)

      url_scheme = if host_port == 443, do: "https", else: "http"

      config =
        Keyword.put(config, :http, port: port)
        |> Keyword.put(:url, host: host, port: host_port, scheme: url_scheme)

      {:ok, config}
    else
      {:ok, config}
    end
  end

  defp get_env(var, type) when is_binary(var) and type in [:str, :int] do
    val = System.get_env(var) || raise "Environment variable '#{var}' missing!"
    get_with_type(val, type)
  end

  defp get_with_type(val, :str), do: val
  defp get_with_type(val, :int), do: String.to_integer(val)
end
