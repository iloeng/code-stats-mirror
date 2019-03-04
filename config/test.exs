use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :code_stats, CodeStatsWeb.Endpoint,
  http: [port: 4001],
  server: false,
  secret_key_base: "fowgaszhasehasehawey34634u34h34js34hejues4ues4use4ys4eue4su4suy4o"

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :code_stats, CodeStats.Repo,
  username: "postgres",
  password: "postgres",
  database: "code_stats_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
