defmodule CodeStats do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      # Start the Ecto repository first for database access
      supervisor(CodeStats.Repo, []),

      # Get historical XP data to cache
      supervisor(CodeStats.XPHistoryCache, []),

      # Start the endpoint when the application starts
      supervisor(CodeStatsWeb.Endpoint, []),

      # Start The Terminator
      worker(CodeStats.User.Terminator, [])
    ]

    # Start XPCacheRefresher if in prod
    children =
      case Mix.env() do
        :dev -> children
        _ -> children ++ [worker(CodeStats.XP.XPCacheRefresher, [])]
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
