defmodule Mix.Tasks.Frontend.Clean do
  use MBU.BuildTask, auto_path: false, create_out_path: false
  import CodeStats.FrontendConfs

  @shortdoc "Clean build artifacts"

  task _ do
    File.rm_rf!(Application.get_env(:mbu, :tmp_path))
    File.rm_rf!(base_dist_path())
  end
end
