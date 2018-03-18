defmodule Mix.Tasks.Frontend.Build.Css.Copy do
  use MBU.BuildTask, auto_path: false
  import CodeStats.FrontendConfs

  @shortdoc "Copy compiled frontend CSS to target dir"

  @deps [
    "frontend.build.css.compile"
  ]

  def in_path(), do: Mix.Tasks.Frontend.Build.Css.Compile.out_path()
  def out_path(), do: Path.join([base_dist_path(), "css"])

  task _ do
    File.cp_r!(in_path(), out_path())
  end
end
