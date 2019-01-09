defmodule CodeStatsWeb.PreferencesControllerTests do
  use CodeStatsWeb.ConnCase

  alias CodeStats.UserHelpers
  alias CodeStats.{User, Repo}

  setup context do
    {:ok, user} = UserHelpers.create_user("foo@bar", "foo", "abcdef")
    Map.put(context, :user, user)
  end

  test "unauthed user cannot view preferences", %{conn: conn} do
    conn = get(conn, "/my/preferences")
    assert is_binary(html_response(conn, 403))
  end

  test "authed user can view preferences", %{conn: conn, user: user} do
    conn = conn |> UserHelpers.force_login(user) |> get("/my/preferences")
    assert is_binary(html_response(conn, 200))
  end

  test "email edit", %{conn: conn, user: user} do
    conn =
      conn
      |> UserHelpers.force_login(user)
      |> put("/my/preferences", %{user: %{type: "edit", email: "bar@baz"}})

    assert redirected_to(conn) == "/my/preferences"

    user = from(u in User, where: u.id == ^user.id) |> Repo.one!()
    assert user.email == "bar@baz"
  end

  test "removal of email", %{conn: conn, user: user} do
    conn =
      conn
      |> UserHelpers.force_login(user)
      |> put("/my/preferences", %{user: %{type: "edit", email: ""}})

    assert redirected_to(conn) == "/my/preferences"

    user = from(u in User, where: u.id == ^user.id) |> Repo.one!()
    assert is_nil(user.email)
  end

  test "private profile edit", %{conn: conn, user: user} do
    conn =
      conn
      |> UserHelpers.force_login(user)
      |> put("/my/preferences", %{
        user: %{type: "edit", email: user.email, private_profile: "true"}
      })

    assert redirected_to(conn) == "/my/preferences"

    user = from(u in User, where: u.id == ^user.id) |> Repo.one!()
    assert user.private_profile
  end

  test "invalid email", %{conn: conn, user: user} do
    conn =
      conn
      |> UserHelpers.force_login(user)
      |> put("/my/preferences", %{
        user: %{type: "edit", email: "bar"}
      })

    assert html_response(conn, 200) =~ "Error updating preferences"
  end

  test "password change", %{conn: conn, user: user} do
    conn =
      conn
      |> UserHelpers.force_login(user)
      |> put("/my/preferences", %{
        user: %{type: "password", old_password: "abcdef", password: "abcdef"}
      })

    assert redirected_to(conn) == "/my/preferences"

    new_user = from(u in User, where: u.id == ^user.id) |> Repo.one!()
    assert new_user.password != user.password
  end

  test "too short password", %{conn: conn, user: user} do
    conn =
      conn
      |> UserHelpers.force_login(user)
      |> put("/my/preferences", %{
        user: %{type: "password", old_password: "abcdef", password: "abcde"}
      })

    assert html_response(conn, 200) =~ "should be at least 6 character(s)"

    new_user = from(u in User, where: u.id == ^user.id) |> Repo.one!()
    assert new_user.password == user.password
  end

  test "old password wrong", %{conn: conn, user: user} do
    conn =
      conn
      |> UserHelpers.force_login(user)
      |> put("/my/preferences", %{
        user: %{type: "password", old_password: "def", password: "abcdef"}
      })

    assert html_response(conn, 200) =~ "does not match"

    new_user = from(u in User, where: u.id == ^user.id) |> Repo.one!()
    assert new_user.password == user.password
  end

  test "invalid edit", %{conn: conn, user: user} do
    conn =
      conn
      |> UserHelpers.force_login(user)
      |> put("/my/preferences", %{foo: "bar"})

    assert html_response(conn, 200) =~ "Unknown error in preferences"
  end

  test "delete user", %{conn: conn, user: user} do
    conn =
      conn
      |> UserHelpers.force_login(user)
      |> delete("/my/preferences", %{delete_confirmation: "DELETE"})

    assert redirected_to(conn) == "/"

    # This is dirty, delete is run in background task so wait for that to complete
    Process.sleep(1_000)

    deleted_user = from(u in User, where: u.id == ^user.id) |> Repo.one()
    assert is_nil(deleted_user)
  end

  test "wrong input for delete", %{conn: conn, user: user} do
    conn =
      conn
      |> UserHelpers.force_login(user)
      |> delete("/my/preferences", %{delete_confirmation: "dElEtE"})

    assert redirected_to(conn) == "/my/preferences"
  end
end
