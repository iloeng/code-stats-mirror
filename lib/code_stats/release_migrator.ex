defmodule CodeStats.ReleaseMigrator do
  @moduledoc """
  Tasks for migrating the DB that can be run from a release.
  """

  @start_apps [
    :crypto,
    :ssl,
    :postgrex,
    :ecto
  ]

  @doc """
  Initialise DB by running migrations and then seed scripts.
  """
  def seed() do
    # Run migrations
    migrate()

    # Run seed script
    Enum.each(repos(), &run_seeds_for/1)

    # Signal shutdown
    IO.puts("Success!")
    :init.stop()
  end

  @doc """
  Run pending migrations for the DB.
  """
  def migrate() do
    prepare()
    Enum.each(repos(), &run_migrations_for/1)
  end

  defp myapp(), do: :code_stats

  defp repos(), do: Application.get_env(myapp(), :ecto_repos, [])

  defp priv_dir(app), do: "#{:code.priv_dir(app)}"

  defp run_seeds_for(repo) do
    # Run the seed script if it exists
    seed_script = seeds_path(repo)

    if File.exists?(seed_script) do
      IO.puts("Running seed script...")
      Code.eval_file(seed_script)
    end
  end

  defp migrations_path(repo), do: priv_path_for(repo, "migrations")

  defp seeds_path(repo), do: priv_path_for(repo, "seeds.exs")

  defp priv_path_for(repo, filename) do
    app = Keyword.get(repo.config, :otp_app)
    repo_underscore = repo |> Module.split() |> List.last() |> Macro.underscore()
    Path.join([priv_dir(app), repo_underscore, filename])
  end

  defp run_migrations_for(repo) do
    app = Keyword.get(repo.config, :otp_app)
    IO.puts("Running migrations for #{app}")
    Ecto.Migrator.run(repo, migrations_path(repo), :up, all: true)
  end

  defp prepare() do
    me = myapp()

    # Force start Ecto SQL apps
    {:ok, _} = Application.ensure_all_started(:ecto_sql)

    # Load the code for myapp, but don't start it
    IO.puts("Loading #{me}...")

    case Application.load(me) do
      :ok -> :ok
      {:error, {:already_loaded, :code_stats}} -> :ok
      err -> raise "Unknown state for application load: #{inspect(err)}"
    end

    # Start apps necessary for executing migrations
    IO.puts("Starting dependencies...")
    Enum.each(@start_apps, &Application.ensure_all_started/1)

    # Start the Repo(s) for myapp
    IO.puts("Starting repos...")
    Enum.each(repos(), & &1.start_link(pool_size: 2))
  end
end
