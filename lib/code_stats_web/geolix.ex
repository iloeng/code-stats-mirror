defmodule CodeStatsWeb.Geolix do
  @moduledoc """
  Module for initialising Geolix databases at runtime instead of config time.
  """

  @spec init() :: :ok
  def init() do
    db_dir = Application.app_dir(:code_stats, "priv")

    databases = [
      %{
        id: :city,
        adapter: Geolix.Adapter.MMDB2,
        source: Path.join([db_dir, "geoip-cities.gz"])
      },
      %{
        id: :country,
        adapter: Geolix.Adapter.MMDB2,
        source: Path.join([db_dir, "geoip-countries.gz"])
      }
    ]

    Application.put_env(:geolix, :databases, databases)
  end
end
