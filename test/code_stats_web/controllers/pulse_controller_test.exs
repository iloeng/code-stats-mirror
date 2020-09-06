defmodule CodeStatsWeb.PulseControllerTest do
  use CodeStatsWeb.ConnCase

  alias CodeStats.User.Machine
  alias CodeStats.User.Pulse
  alias CodeStats.XP
  alias CodeStats.Language
  alias CodeStatsWeb.AuthUtils
  alias CodeStats.UserHelpers

  describe "as a not authenticated user" do
    test "GET /my/pulses should return 403 forbidden", %{conn: conn} do
      conn =
        conn
        |> put_req_header("accept", "text/csv")
        |> get("/my/pulses")

      assert conn.status == 403
    end

    test "POST /api/my/pulses should return 403 forbidden", %{conn: conn} do
      conn = conn |> put_req_header("accept", "application/json") |> post("/api/my/pulses", %{})

      assert conn.status == 403
    end
  end

  describe "as an authenticated user with some pulses" do
    setup do
      {:ok, language} = Language.get_or_create("elixir")

      {:ok, user} = UserHelpers.create_user("user@somewhere", "test_user")
      {:ok, another_user} = UserHelpers.create_user("another_user@somewhere", "another_test_user")

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

      assert conn.resp_body ==
               "sent_at;sent_at_local;tz_offset;language;machine;amount\n2017-11-27 23:00:00Z;2017-11-28 00:00:00;60;elixir;test_machine;1\n"
    end
  end

  describe "as an authenticated user with no pulses" do
    setup [:create_user]

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

  describe "with a machine" do
    setup [:create_user, :create_machine]

    test "creating new pulse works", %{conn: conn, user: user, machine: machine} do
      conn =
        conn
        |> creation_request(user, machine)
        |> post("/api/my/pulses", %{
          coded_at: DateTime.utc_now() |> DateTime.to_iso8601(),
          xps: [
            %{language: "Rust", xp: 15},
            %{language: "Elixir", xp: 30}
          ]
        })

      assert conn.status == 201
      assert conn.resp_body == ~s({"ok":"Great success!"})

      pulses = CodeStats.Repo.all(CodeStats.User.Pulse)
      assert length(pulses) == 1

      langs = CodeStats.Repo.all(CodeStats.Language)
      assert length(langs) == 2
      lang_names = for l <- langs, into: MapSet.new(), do: l.name
      assert MapSet.equal?(lang_names, MapSet.new(["Rust", "Elixir"]))

      xps = CodeStats.Repo.all(CodeStats.XP) |> CodeStats.Repo.preload(:language)
      assert length(xps) == 2
      datas = for x <- xps, into: %{}, do: {x.language.name, x.amount}
      assert datas == %{"Rust" => 15, "Elixir" => 30}
    end

    test "creating new pulse with invalid format doesn't work", %{
      conn: conn,
      user: user,
      machine: machine
    } do
      conn =
        conn
        |> creation_request(user, machine)
        |> post("/api/my/pulses", %{
          coded_at: DateTime.utc_now() |> DateTime.to_iso8601(),
          xps: [
            %{language: "Rust", xp: 15},
            %{languagezzz: "Elixir", xp: 30}
          ]
        })

      assert conn.status == 400

      pulses = CodeStats.Repo.all(CodeStats.User.Pulse)
      assert length(pulses) == 0
    end

    test "creating new pulse with negative amount doesn't work", %{
      conn: conn,
      user: user,
      machine: machine
    } do
      conn =
        conn
        |> creation_request(user, machine)
        |> post("/api/my/pulses", %{
          coded_at: DateTime.utc_now() |> DateTime.to_iso8601(),
          xps: [
            %{language: "Rust", xp: 15},
            %{language: "Elixir", xp: -1000}
          ]
        })

      assert conn.status == 400

      pulses = CodeStats.Repo.all(CodeStats.User.Pulse)
      assert length(pulses) == 0
    end

    test "creating new pulse with empty language name adds plain text", %{
      conn: conn,
      user: user,
      machine: machine
    } do
      conn =
        conn
        |> creation_request(user, machine)
        |> post("/api/my/pulses", %{
          coded_at: DateTime.utc_now() |> DateTime.to_iso8601(),
          xps: [
            %{language: "", xp: 15}
          ]
        })

      assert conn.status == 201

      xps = CodeStats.Repo.all(CodeStats.XP) |> CodeStats.Repo.preload(:language)
      assert length(xps) == 1
      assert Enum.at(xps, 0).language.name == "Plain text"
    end

    test "creating pulse with older time works", %{
      conn: conn,
      user: user,
      machine: machine
    } do
      conn =
        conn
        |> creation_request(user, machine)
        |> post("/api/my/pulses", %{
          coded_at:
            DateTime.utc_now() |> Calendar.DateTime.subtract!(86_400 * 5) |> DateTime.to_iso8601(),
          xps: [
            %{language: "Rust", xp: 15},
            %{language: "Elixir", xp: 30}
          ]
        })

      assert conn.status == 201
    end

    test "creating pulse with local time works", %{
      conn: conn,
      user: user,
      machine: machine
    } do
      conn =
        conn
        |> creation_request(user, machine)
        |> post("/api/my/pulses", %{
          coded_at:
            DateTime.utc_now()
            |> Calendar.DateTime.shift_zone!("Europe/Helsinki")
            |> DateTime.to_iso8601(),
          xps: [
            %{language: "Rust", xp: 15},
            %{language: "Elixir", xp: 30}
          ]
        })

      assert conn.status == 201
    end

    test "creating pulse with local time (negative offset) works", %{
      conn: conn,
      user: user,
      machine: machine
    } do
      conn =
        conn
        |> creation_request(user, machine)
        |> post("/api/my/pulses", %{
          coded_at:
            DateTime.utc_now()
            |> Calendar.DateTime.shift_zone!("America/New_York")
            |> DateTime.to_iso8601(),
          xps: [
            %{language: "Rust", xp: 15},
            %{language: "Elixir", xp: 30}
          ]
        })

      assert conn.status == 201
    end

    test "creating pulse with too old time doesn't work", %{
      conn: conn,
      user: user,
      machine: machine
    } do
      conn =
        conn
        |> creation_request(user, machine)
        |> post("/api/my/pulses", %{
          coded_at:
            DateTime.utc_now() |> Calendar.DateTime.subtract!(86_400 * 8) |> DateTime.to_iso8601(),
          xps: [
            %{language: "Rust", xp: 15},
            %{language: "Elixir", xp: 30}
          ]
        })

      assert conn.status == 400

      pulses = CodeStats.Repo.all(CodeStats.User.Pulse)
      assert length(pulses) == 0
    end

    test "creating pulse with invalid time doesn't work", %{
      conn: conn,
      user: user,
      machine: machine
    } do
      conn =
        conn
        |> creation_request(user, machine)
        |> post("/api/my/pulses", %{
          coded_at: "23626",
          xps: [
            %{language: "Rust", xp: 15},
            %{language: "Elixir", xp: 30}
          ]
        })

      assert conn.status == 400

      pulses = CodeStats.Repo.all(CodeStats.User.Pulse)
      assert length(pulses) == 0
    end

    test "creating pulse invalid format doesn't work", %{
      conn: conn,
      user: user,
      machine: machine
    } do
      conn =
        conn
        |> creation_request(user, machine)
        |> post("/api/my/pulses", %{
          bah: "humbug"
        })

      assert conn.status == 400

      pulses = CodeStats.Repo.all(CodeStats.User.Pulse)
      assert length(pulses) == 0
    end

    test "creating pulse with aliased language works", %{
      conn: conn,
      user: user,
      machine: machine
    } do
      # This is for u nox
      CodeStats.Language.AdminCommands.alias_language("C++", "Rust")

      conn =
        conn
        |> creation_request(user, machine)
        |> post("/api/my/pulses", %{
          coded_at: DateTime.utc_now() |> DateTime.to_iso8601(),
          xps: [
            %{language: "C++", xp: 15}
          ]
        })

      assert conn.status == 201

      xps =
        CodeStats.Repo.all(CodeStats.XP)
        |> CodeStats.Repo.preload([:language, :original_language])

      assert length(xps) == 1
      assert Enum.at(xps, 0).language.name == "Rust"
      assert Enum.at(xps, 0).original_language.name == "C++"
    end
  end

  defp create_user(_context) do
    {:ok, user} = UserHelpers.create_user("user@somewhere", "test_user")
    %{user: user}
  end

  defp create_machine(%{user: user}) do
    {:ok, machine} = UserHelpers.create_machine(user, "incredibile")
    %{machine: machine}
  end

  defp creation_request(conn, user, machine) do
    conn
    |> Plug.Test.init_test_session(%{})
    |> put_req_header("accept", "application/json")
    |> put_req_header("x-api-token", CodeStatsWeb.AuthUtils.get_machine_key(conn, user, machine))
  end

  defp authenticated_as(conn, user) do
    conn
    |> Plug.Test.init_test_session(%{})
    |> AuthUtils.force_auth_user_id(user.id)
  end

  defp contains?(headers, key, value), do: Enum.member?(headers, {key, value})

  defp create_data_for(user, language) do
    {:ok, machine} =
      Machine.create_changeset(%{name: "test_machine", user: user})
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
