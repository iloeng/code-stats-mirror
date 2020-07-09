defmodule CodeStatsWeb.SupportController do
  use CodeStatsWeb, :controller

  @spec page(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def page(conn, _params) do
    render(conn, "page.html")
  end
end
