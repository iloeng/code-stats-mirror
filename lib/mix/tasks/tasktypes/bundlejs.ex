defmodule CodeStats.BuildTasks.BundleJS do
  import MBU.TaskUtils
  import CodeStats.FrontendConfs

  def bin(), do: node_bin("webpack")

  def args(in_file, out_file) do
    [
      "--mode",
      "development",
      "--config",
      "assets/webpack.config.js",
      "--entry",
      in_file,
      "--output",
      out_file
    ]
  end

  def task(in_file, out_file) do
    bin() |> exec(args(in_file, out_file)) |> listen()

    print_size(out_file)
  end
end
