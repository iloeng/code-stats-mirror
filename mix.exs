defmodule CodeStats.Mixfile do
  use Mix.Project

  def project do
    [
      app: :code_stats,
      version: "2.2.0",
      elixir: "~> 1.10",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),

      # Docs
      name: "Code::Stats",
      source_url: "https://gitlab.com/code-stats/code-stats",
      homepage_url: "https://codestats.net",
      docs: [
        # The main page in the docs
        main: "readme",
        logo: "assets/logos/Logo-crushed.png",
        extras: ["README.md"]
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {CodeStats, []},
      extra_applications: [:logger]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(:ci), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.5.1"},
      {:postgrex, ">= 0.15.3"},
      {:phoenix_pubsub, "~> 2.0"},
      {:phoenix_ecto, "~> 4.1"},
      {:ecto_sql, "~> 3.4"},
      {:phoenix_html, "~> 2.14"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:jason, "~> 1.2", override: true},
      {:gettext, "~> 0.17.4"},
      {:cowboy, "~> 2.7"},
      {:plug_cowboy, "~> 2.2"},
      {:comeonin, "~> 5.3"},
      {:bcrypt_elixir, "~> 2.2"},
      {:number, "~> 1.0"},
      {:earmark, "~> 1.4", only: :dev},
      {:ex_doc, "~> 0.21.3", only: :dev},
      {:calendar, "~> 1.0"},
      {:bamboo, "~> 1.4"},
      {:corsica, "~> 1.1"},
      {:appsignal, "~> 1.13"},
      {:mbu, "~> 3.0.0", runtime: false},
      {:geolix, "~> 1.0"},
      {:geolix_adapter_mmdb2, "~> 0.4.0"},
      {:remote_ip, "~> 0.2.1"},
      {:absinthe, "~> 1.5.0-rc.5"},
      {:absinthe_plug, "~> 1.5.0-rc.2"},
      {:ex2ms, "~> 1.6"},
      {:csv, "~> 2.3"},
      {:tzdata, "~> 1.0"}
    ]
  end

  # Aliases are shortcut or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
