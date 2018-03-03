defmodule CodeStatsWeb.MachineView do
  use CodeStatsWeb, :view

  import CodeStats.User.Machine, only: [machine_name_max_length: 0]
end
