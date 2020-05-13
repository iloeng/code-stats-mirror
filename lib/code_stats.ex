defmodule CodeStats do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      # Start the Ecto repository first for database access
      {CodeStats.Repo, []},

      # PubSub runs channel system
      {Phoenix.PubSub, [name: CodeStats.PubSub]},

      # Get historical XP data to cache
      {CodeStats.XPHistoryCache, [name: CodeStats.XPHistoryCache]},

      # Start the endpoint when the application starts
      {CodeStatsWeb.Endpoint, [name: CodeStatsWeb.Endpoint]},

      # Start The Terminator
      {CodeStats.User.Terminator, [name: CodeStats.User.Terminator]}
    ]

    # Start XPCacheRefresher if in prod or if told to
    children =
      case {CodeStats.Utils.get_conf(:compile_env), System.get_env("RUN_CACHES")} do
        {:dev, nil} -> children
        _ -> children ++ [{CodeStats.XP.XPCacheRefresher, [name: CodeStats.XP.XPCacheRefresher]}]
      end

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: CodeStats.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    CodeStatsWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
