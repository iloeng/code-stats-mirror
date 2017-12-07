# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Configures the endpoint
config :code_stats, CodeStatsWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "gWdaZrx0+CB8iuwoC1LMNUD2Lp37PCqvv73Dgid6k+jESaQFWguzrf2hDAoIYE4U",
  render_errors: [accepts: ~w(html json)],
  pubsub: [name: CodeStats.PubSub, adapter: Phoenix.PubSub.PG2]

# Email config, override in your env.secret.exs
config :code_stats, CodeStats.Mailer,
  adapter: Bamboo.MailgunAdapter,
  api_key: "",
  domain: "domain.example"

config :code_stats,
  ecto_repos: [CodeStats.Repo],

  # User configurable settings below
  ##################################

  # Set to true if site is in beta mode. This shows a big banner to users
  # that announces the fact.
  beta_mode: false,
  site_name: "Code::Stats",

  # Address to send email from in the form of {"Name", "address@domain.example"}
  email_from: {"Code::Stats", "address@domain.example"},

  # Social links to insert in the website's footer, list of 2-tuples in the form of
  # {"Link name", "Full link URL"}
  social_links: [
    {"Twitter", "https://twitter.com/example"},
    {"IRC", "irc://irc.freenode.net/codestats"}
  ],

  # Extra HTML that is injected to every page, right before </body>. Useful for analytics scripts.
  analytics_code: """
  <script>
    (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
    (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
    m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
    })(window,document,'script','//www.google-analytics.com/analytics.js','ga');

    ga('create', 'my-googleanalytics-id', 'auto');
    ga('send', 'pageview');
  </script>
  """,

  # CORS

  # Allowed origins in a format that Corsica understands, see:
  # https://hexdocs.pm/corsica/Corsica.html#module-origins
  cors_allowed_origins: []

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Configure GitHub authentication
# Copy this to dev.secret.exs or prod.secret.exs and add proper variables
# See CodeStats.Auth.Github for more documentation
config :code_stats, CodeStats.Auth.Github,
  enabled: false,
  client_id: nil,
  client_secret: nil

# Configure phoenix generators
config :phoenix, :generators,
  migration: true,
  binary_id: false

config :comeonin, bcrypt_log_rounds: 12

config :number,
  delimiter: [
    precision: 0,
    delimiter: ",",
    separator: "."
  ]

config :geolix, init: {CodeStatsWeb.Geolix, :init}

config :geolite2data,
  geolix_updater: true,
  logger: true

# Appsignal configuration

config :code_stats, CodeStatsWeb.Endpoint, instrumenters: [Appsignal.Phoenix.Instrumenter]

config :phoenix, :template_engines,
  eex: Appsignal.Phoenix.Template.EExEngine,
  exs: Appsignal.Phoenix.Template.ExsEngine

config :code_stats, CodeStats.Repo, loggers: [Appsignal.Ecto, Ecto.LogEntry]

config :appsignal, :config,
  filter_parameters: [
    "password",
    "username",
    "user_email",
    "email",
    "new_password",
    "old_password",
    "machine_name"
  ]

# Store mix env used to compile app, since Mix won't be available in release
config :code_stats, compile_env: Mix.env()

# Store app version and commit hash at compile time
config :code_stats,
  commit_hash: System.cmd("git", ["rev-parse", "--verify", "--short", "HEAD"]) |> elem(0),
  version: Mix.Project.config()[:version]

import_config "appsignal.exs"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
