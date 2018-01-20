defmodule CodeStatsWeb.PageController do
  use CodeStatsWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def api_docs(conn, _params) do
    conn
    |> assign(:title, "API docs")
    |> render("api_docs.html")
  end

  def terms(conn, _params) do
    conn
    |> assign(:title, "Legal")
    |> render("terms.html")
  end

  def plugins(conn, _params) do
    conn
    |> assign(:title, "Plugins")
    |> render("plugins.html")
  end

  def changes(conn, _params) do
    conn
    |> assign(:title, "Changes")
    |> render("changes.html")
  end

  def contact(conn, _params) do
    conn
    |> assign(:title, "Contact")
    |> render("contact.html")
  end
end
