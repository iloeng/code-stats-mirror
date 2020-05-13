defmodule CodeStatsWeb.Geolix do
  @moduledoc """
  Module for initialising Geolix databases at runtime instead of config time.
  """

  @spec init() :: :ok
  def init() do
    db_dir = Application.app_dir(:code_stats, "priv") |> Path.join("maxmind")

    databases = [
      %{
        id: :city,
        adapter: Geolix.Adapter.MMDB2,
        source: Path.join([db_dir, "city", "GeoLite2-City.mmdb"])
      },
      %{
        id: :country,
        adapter: Geolix.Adapter.MMDB2,
        source: Path.join([db_dir, "country", "GeoLite2-Country.mmdb"])
      }
    ]

    Application.put_env(:geolix, :databases, databases)
  end
end
