defmodule CodeStatsWeb.LayoutView do
  use CodeStatsWeb, :view

  def get_title(conn) do
    site_name = get_conf(:site_name)

    if conn.assigns[:title] do
      "#{conn.assigns[:title]} – #{site_name}"
    else
      site_name
    end
  end

  @doc """
  Check if user is authenticated. If session is not fetched, return false.
  """
  def is_authed?(conn) do
    try do
      CodeStatsWeb.AuthUtils.is_authed?(conn)
    rescue
      _ -> false
    end
  end

  @doc """
  Get flash of given type if fetched, otherwise returns nil.
  """
  def get_flash(conn, type) do
    try do
      Phoenix.Controller.get_flash(conn, type)
    rescue
      _ -> nil
    end
  end
end
