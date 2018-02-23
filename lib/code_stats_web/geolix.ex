defmodule CodeStatsWeb.Geolix do
  @moduledoc """
  Module for initialising Geolix databases at runtime instead of config time.
  """

  def init() do
    priv_dir = Application.app_dir(:code_stats, "priv")

    Geolix.load_database(%{
      id: :city,
      adapter: Geolix.Adapter.MMDB2,
      source: Path.join([priv_dir, "geoip-cities.gz"])
    })

    Geolix.load_database(%{
      id: :country,
      adapter: Geolix.Adapter.MMDB2,
      source: Path.join([priv_dir, "geoip-countries.gz"])
    })
  end
end
