defmodule CodeStats.BuildTasks.MinifyJS do
  import MBU.TaskUtils
  import CodeStats.FrontendConfs

  def bin(), do: node_bin("uglifyjs")

  def args(in_file, out_file) do
    [
      "--source-map",
      "filename='#{out_file}.map',content='#{in_file}.map',url='#{Path.basename(out_file)}.map'",
      "--compress",
      "--mangle",
      # ;_;
      "--safari10",
      "--ecma",
      "8",
      "--comments",
      "--timings",
      "-o",
      out_file,
      "--",
      in_file
    ]
  end

  def task(in_file, out_file) do
    bin() |> exec(args(in_file, out_file)) |> listen()

    print_size(out_file, in_file)
  end
end
