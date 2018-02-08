defmodule Mix.Tasks.Frontend.Build.Css do
  use MBU.BuildTask
  import MBU.TaskUtils

  @shortdoc "Build the frontend CSS"

  task _ do
    todo =
      case System.get_env("MINIFY") do
        # Never minify because cssnano breaks our grids: https://github.com/ben-eb/cssnano/issues/261
        # "true" -> "frontend.build.css.minify"
        _ ->
          "frontend.build.css.copy"
      end

    run_task(todo)
  end
end
