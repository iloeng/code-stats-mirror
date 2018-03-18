defmodule Mix.Tasks.Frontend.Build.Css.Compile do
  use MBU.BuildTask
  import CodeStats.FrontendConfs
  alias CodeStats.BuildTasks.CompileCSS

  @shortdoc "Compile the SCSS sources"

  def in_path(), do: Path.join([base_src_path(), "css", "frontend"])
  def in_file(), do: Path.join([in_path(), "frontend.scss"])

  task _ do
    CompileCSS.task(out_path(), in_file())
  end
end
