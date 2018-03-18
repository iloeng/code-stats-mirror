defmodule Mix.Tasks.Frontend.Build.Assets do
  use MBU.BuildTask, auto_path: false
  import CodeStats.FrontendConfs

  @shortdoc "Copy frontend assets to target dir"

  @deps []

  def in_path(), do: Path.join([base_src_path(), "assets"])
  def out_path(), do: Path.join([base_dist_path(), "assets"])

  task _ do
    File.cp_r!(in_path(), out_path())
  end
end
