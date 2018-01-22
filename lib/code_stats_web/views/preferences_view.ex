defmodule CodeStatsWeb.PreferencesView do
  use CodeStatsWeb, :view

  def get_flash(conn, type), do: CodeStatsWeb.LayoutView.get_flash(conn, type)
end
