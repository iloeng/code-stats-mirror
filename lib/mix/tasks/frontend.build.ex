defmodule Mix.Tasks.Frontend.Build do
  use MBU.BuildTask, auto_path: false, create_out_path: false
  import MBU.TaskUtils

  @shortdoc "Build the frontend"

  @deps [
    "frontend.clean"
  ]

  task _ do
    run_tasks([
      "frontend.build.js",
      "frontend.build.css",
      "frontend.build.assets"
    ])
  end
end
