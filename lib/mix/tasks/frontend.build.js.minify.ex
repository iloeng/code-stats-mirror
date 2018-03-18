defmodule Mix.Tasks.Frontend.Build.Js.Minify do
  use MBU.BuildTask, auto_path: false
  import CodeStats.FrontendConfs
  alias CodeStats.BuildTasks.MinifyJS

  @shortdoc "Minify built JS files"

  @deps [
    "frontend.build.js.bundle"
  ]

  def in_path(), do: Mix.Tasks.Frontend.Build.Js.Bundle.out_path()
  def in_file(), do: Path.join([in_path(), "frontend.js"])

  def out_path(), do: Path.join([base_dist_path(), "js"])
  def out_file(), do: Path.join([out_path(), "frontend.js"])

  task _ do
    MinifyJS.task(in_file(), out_file())
  end
end
