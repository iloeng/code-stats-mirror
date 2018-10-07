defmodule CodeStats.Mixfile do
  use Mix.Project

  def project do
    [
      app: :code_stats,
      version: "2.0.4",
      elixir: "~> 1.6",
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
        logo: "Logo.png",
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
      {:phoenix, "~> 1.3.0"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_pubsub, "~> 1.0.2"},
      {:phoenix_ecto, "~> 3.3.0"},
      {:phoenix_html, "~> 2.11.1"},
      {:phoenix_live_reload, "~> 1.1.2", only: :dev},
      {:gettext, "~> 0.15"},
      {:cowboy, "~> 1.0"},
      {:comeonin, "~> 4.1.1"},
      {:bcrypt_elixir, "~> 1.0.4"},
      {:number, "~> 0.5.4"},
      {:earmark, "~> 1.2.3", only: :dev},
      {:ex_doc, "~> 0.18", only: :dev},
      {:calendar, "~> 0.17.4"},
      {:bamboo, "~> 1.0.0"},
      {:corsica, "~> 1.1.0"},
      {:appsignal, "~> 1.4"},
      {:mbu, "~> 3.0.0", runtime: false},
      {:geolix, "~> 0.16.0"},
      {:geolite2data, "~> 0.0.3"},
      {:remote_ip, "~> 0.1.3"},
      {:distillery, "~> 1.5.2", runtime: false},
      {:absinthe, "~> 1.4.13"},
      {:absinthe_plug, "~> 1.4.5"},
      {:ex2ms, "~> 1.5"},
      {:csv, "~> 2.1.1"}
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
