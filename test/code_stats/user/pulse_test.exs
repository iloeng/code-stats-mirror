defmodule CodeStats.User.PulseTest do
  use CodeStats.DatabaseCase

  alias CodeStats.User.Pulse
  alias CodeStats.UserHelpers

  @invalid_attrs %{}

  test "changeset with valid attributes" do
    {:ok, user} = UserHelpers.create_user("a@a", "foo")
    {:ok, machine} = UserHelpers.create_machine(user, "machina")

    assert {:ok, _} =
             Repo.insert(
               Pulse.changeset(%Pulse{user_id: user.id, machine_id: machine.id}, %{
                 sent_at: "2010-04-17 14:00:00",
                 sent_at_local: "2010-04-17 14:00:00",
                 tz_offset: "0"
               })
             )
  end

  test "changeset with invalid attributes" do
    assert {:error, _} = Repo.insert(Pulse.changeset(%Pulse{}, @invalid_attrs))
  end
end
