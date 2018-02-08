defmodule Mix.Tasks.Frontend.Build.Assets do
  use MBU.BuildTask
  import CodeStats.FrontendConfs
  alias CodeStats.BuildTasks.Copy

  @shortdoc "Copy frontend assets to target dir"

  @deps []

  def in_path(), do: Path.join([base_src_path(), "assets"])
  def out_path(), do: Path.join([base_dist_path(), "assets"])

  task _ do
    Copy.task(in_path(), out_path())
  end
end
