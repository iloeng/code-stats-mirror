defmodule Mix.Tasks.Frontend.Watch do
  use MBU.BuildTask, auto_path: false, create_out_path: false
  import MBU.TaskUtils
  alias Mix.Tasks.Frontend.Build.Js.Bundle, as: FrontendBundleJS
  alias Mix.Tasks.Frontend.Build.Js.Copy, as: FrontendCopyJS
  alias Mix.Tasks.Frontend.Build.Css.Compile, as: FrontendCompileCSS
  alias Mix.Tasks.Frontend.Build.Css.Copy, as: FrontendCopyCSS
  alias Mix.Tasks.Frontend.Build.Assets, as: FrontendAssets

  @shortdoc "Watch frontend assets and rebuild when necessary"

  @deps [
    "frontend.build"
  ]

  task _ do
    [
      exec(
        CodeStats.BuildTasks.BundleJS.bin(),
        CodeStats.BuildTasks.BundleJS.args(
          FrontendBundleJS.in_file(),
          FrontendBundleJS.out_file()
        ) ++ ["--watch"]
      ),
      watch(
        "CopyFrontendJS",
        FrontendCopyJS.in_path(),
        FrontendCopyJS
      ),
      watch(
        "CompileFrontendCSS",
        FrontendCompileCSS.in_path(),
        FrontendCompileCSS
      ),
      watch(
        "CopyFrontendCSS",
        FrontendCopyCSS.in_path(),
        FrontendCopyCSS
      ),
      watch(
        "CopyFrontendAssets",
        FrontendAssets.in_path(),
        FrontendAssets
      )
    ]
    |> listen(watch: true)
  end
end
