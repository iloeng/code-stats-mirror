defmodule CodeStatsWeb.PulseControllerTest do
  use CodeStatsWeb.ConnCase

  alias CodeStats.User
  alias CodeStats.User.Machine
  alias CodeStats.User.Pulse
  alias CodeStats.XP
  alias CodeStats.Language
  alias CodeStatsWeb.AuthUtils

  describe "as a not authenticated user" do
    test "GET /my/pulses should return 403 forbidden", %{conn: conn} do
      conn =
        conn
        |> put_req_header("accept", "text/csv")
        |> get("/my/pulses")

      assert conn.status == 403
    end
  end

  describe "as an authenticated user with some pulses" do
    setup do
      {:ok, language} = Language.get_or_create("elixir")

      {:ok, user} = create_user("user@somewhere", "test_user")
      {:ok, another_user} = create_user("another_user@somewhere", "another_test_user")

      create_data_for(user, language)
      create_data_for(another_user, language)

      %{user: user}
    end

    test "GET /my/pulses should export data in CSV", %{conn: conn, user: user} do
      conn =
        conn
        |> authenticated_as(user)
        |> put_req_header("accept", "text/csv")
        |> get("/my/pulses")

      assert conn.status == 200
      assert conn.resp_headers |> contains?("content-type", "text/csv; charset=utf-8")

      assert conn.resp_headers
             |> contains?("content-disposition", "attachment; filename=\"pulses.csv\"")

      assert conn.resp_body =~ "sent_at;sent_at_local;tz_offset;language;machine;amount\n"

      assert conn.resp_body =~
               "2017-11-27 23:00:00.000000Z;2017-11-28 00:00:00.000000;60;elixir;test_machine;1\n"
    end
  end

  describe "as an authenticated user with no pulses" do
    setup do
      {:ok, user} = create_user("user@somewhere", "test_user")

      %{user: user}
    end

    test "GET /my/pulses should return an empty CSV", %{conn: conn, user: user} do
      conn =
        conn
        |> authenticated_as(user)
        |> put_req_header("accept", "text/csv")
        |> get("/my/pulses")

      assert conn.status == 200
      assert conn.resp_headers |> contains?("content-type", "text/csv; charset=utf-8")

      assert conn.resp_headers
             |> contains?("content-disposition", "attachment; filename=\"pulses.csv\"")

      assert conn.resp_body == "sent_at;sent_at_local;tz_offset;language;machine;amount\n"
    end
  end

  defp authenticated_as(conn, user) do
    conn
    |> init_test_session
    |> AuthUtils.force_auth_user_id(user.id)
  end

  # this should be replaced with the init_test_session
  # of the new Plug. Maybe it is useful to bump the
  # phoenix version
  # See: https://hexdocs.pm/plug/Plug.Test.html#init_test_session/2
  defp init_test_session(conn, _session \\ %{}) do
    conn
    |> put_private(:plug_session, %{})
    |> put_private(:plug_session_fetch, :done)
  end

  defp contains?(headers, key, value), do: Enum.member?(headers, {key, value})

  defp create_user(email, username) do
    %User{email: email, username: username, password: "test_password"}
    |> User.changeset(%{})
    |> Repo.insert()
  end

  defp create_data_for(user, language) do
    {:ok, machine} =
      %Machine{name: "test_machine"}
      |> Machine.changeset(%{})
      |> Ecto.Changeset.put_change(:user_id, user.id)
      |> Repo.insert()

    {:ok, sent_at} = Calendar.DateTime.from_erl({{2017, 11, 27}, {23, 00, 00}}, "Etc/UTC")
    local_datetime = Calendar.DateTime.add!(sent_at, 3600) |> Calendar.DateTime.to_naive()

    {:ok, pulse} =
      Pulse.changeset(%Pulse{sent_at: sent_at, tz_offset: 60, sent_at_local: local_datetime}, %{})
      |> Ecto.Changeset.put_change(:user_id, user.id)
      |> Ecto.Changeset.put_change(:machine_id, machine.id)
      |> Repo.insert()

    {:ok, _} =
      XP.changeset(%XP{amount: 1})
      |> Ecto.Changeset.put_change(:pulse_id, pulse.id)
      |> Ecto.Changeset.put_change(:language_id, language.id)
      |> Ecto.Changeset.put_change(:original_language_id, language.id)
      |> Repo.insert()
  end
end
