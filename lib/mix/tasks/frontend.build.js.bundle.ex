defmodule Mix.Tasks.Frontend.Build.Js.Bundle do
  use MBU.BuildTask
  import CodeStats.FrontendConfs
  alias CodeStats.BuildTasks.BundleJS

  @shortdoc "Bundle and transpile JavaScript sources into bundles"

  def in_path(), do: js_path()
  def in_file(), do: Path.join([in_path(), "frontend", "frontend.js"])

  def out_path(), do: Path.join([base_tmp_path(), "bundled", "js"])
  def out_file(), do: Path.join([out_path(), "frontend.js"])

  task _ do
    BundleJS.task(in_file(), out_file())
  end
end
