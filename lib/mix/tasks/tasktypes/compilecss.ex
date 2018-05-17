defmodule CodeStats.BuildTasks.CompileCSS do
  import MBU.TaskUtils
  import CodeStats.FrontendConfs

  def bin(), do: node_bin("sass")

  def args(in_file, out_file),
    do: [
      "--embed-source-map",
      in_file,
      out_file
    ]

  def task(out_path, in_file) do
    # Output file is input file where extension is changed
    out_file = Path.join([out_path, Path.basename(in_file, "scss") <> "css"])

    bin() |> exec(args(in_file, out_file)) |> listen()

    print_size(out_file)
  end
end
