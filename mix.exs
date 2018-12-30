defmodule CodeStats.Mixfile do
  use Mix.Project

  def project do
    [
      app: :code_stats,
      version: "2.0.5",
      elixir: "~> 1.7",
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
      ],
      test_coverage: [
        tool: Coverex.Task,
        ignore_modules: [
          Mix.Tasks.Frontend.Build,
          Mix.Tasks.Frontend.Clean,
          Mix.Tasks.Frontend.Watch,
          Mix.Tasks.Frontend.Build.Assets,
          Mix.Tasks.Frontend.Build.Css,
          Mix.Tasks.Frontend.Build.Css.Compile,
          Mix.Tasks.Frontend.Build.Css.Copy,
          Mix.Tasks.Frontend.Build.Css.Minify,
          Mix.Tasks.Frontend.Build.Js,
          Mix.Tasks.Frontend.Build.Js.Bundle,
          Mix.Tasks.Frontend.Build.Js.Copy,
          Mix.Tasks.Frontend.Build.Js.Exthelp,
          Mix.Tasks.Frontend.Build.Js.Minify,
          CodeStats.BuildTasks.BundleJS,
          CodeStats.BuildTasks.CompileCSS,
          CodeStats.BuildTasks.MinifyCSS,
          CodeStats.BuildTasks.MinifyJS
        ]
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
      {:phoenix, "~> 1.4.0"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_pubsub, "~> 1.1"},
      {:phoenix_ecto, "~> 4.0"},
      {:ecto_sql, "~> 3.0"},
      {:phoenix_html, "~> 2.12"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:jason, "~> 1.0"},
      {:gettext, "~> 0.15"},
      {:cowboy, "~> 2.0"},
      {:plug_cowboy, "~> 2.0"},
      {:comeonin, "~> 4.1.1"},
      {:bcrypt_elixir, "~> 1.0"},
      {:number, "~> 1.0.0"},
      {:earmark, "~> 1.3", only: :dev},
      {:ex_doc, "~> 0.18", only: :dev},
      {:calendar, "~> 0.17.4"},
      {:bamboo, "~> 1.0"},
      {:corsica, "~> 1.1.0"},
      {:appsignal, "~> 1.4"},
      {:mbu, "~> 3.0.0", runtime: false},
      {:geolix, "~> 0.17.0"},
      {:geolite2data, "~> 0.0.3"},
      {:remote_ip, "~> 0.1.3"},
      {:distillery, "~> 2.0", runtime: false},
      {:absinthe, "~> 1.4.13"},
      {:absinthe_plug, "~> 1.4.5"},
      {:ex2ms, "~> 1.5"},
      {:csv, "~> 2.1.1"},
      {:coverex, "~> 1.4", only: :test}
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
