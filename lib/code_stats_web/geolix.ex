defmodule CodeStatsWeb.Geolix do
  @moduledoc """
  Module for initialising Geolix databases at runtime instead of config time.
  """

  def init_cities(_) do
    priv_dir = Application.app_dir(:code_stats, "priv")

    %{
      id: :city,
      adapter: Geolix.Adapter.MMDB2,
      source: Path.join([priv_dir, "geoip-cities.gz"])
    }
  end

  def init_countries(_) do
    priv_dir = Application.app_dir(:code_stats, "priv")

    %{
      id: :country,
      adapter: Geolix.Adapter.MMDB2,
      source: Path.join([priv_dir, "geoip-countries.gz"])
    }
  end
end
