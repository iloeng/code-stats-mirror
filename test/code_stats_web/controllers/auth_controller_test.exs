defmodule CodeStatsWeb.AuthControllerTest do
  use CodeStatsWeb.ConnCase

  alias CodeStats.UserHelpers

  test "GET /login", %{conn: conn} do
    conn = get(conn, "/login")
    assert is_binary(html_response(conn, 200))
  end

  test "login", %{conn: conn} do
    {:ok, u} = UserHelpers.create_user("foo@bar", "nicd", "abcdefg")
    conn = post(conn, "/login", %{username: u.username, password: "abcdefg"})
    assert redirected_to(conn) == "/my/profile"
  end

  test "nonexistent user", %{conn: conn} do
    {:ok, _} = UserHelpers.create_user("foo@bar", "nicd", "abcdefg")
    conn = post(conn, "/login", %{username: "no-one", password: "abcdefg"})
    response(conn, 404)
  end

  test "wrong password", %{conn: conn} do
    {:ok, u} = UserHelpers.create_user("foo@bar", "nicd", "abcdefg")
    conn = post(conn, "/login", %{username: u.username, password: "123"})
    response(conn, 404)
  end

  test "GET /signup", %{conn: conn} do
    conn = get(conn, "/signup")
    assert is_binary(html_response(conn, 200))
  end

  test "signup", %{conn: conn} do
    conn =
      post(conn, "/signup", %{
        user: %{
          username: "foo",
          password: "abcdefg",
          "not-underage": true,
          "accept-terms": true
        }
      })

    assert redirected_to(conn) == "/login"

    user = from(u in CodeStats.User, where: u.username == "foo") |> Repo.one!()
    assert is_nil(user.email)
    assert user.terms_version == CodeStats.LegalTerms.get_latest_version()
  end

  test "signup with email", %{conn: conn} do
    post(conn, "/signup", %{
      user: %{
        username: "foo",
        password: "abcdefg",
        email: "foo@bar",
        "not-underage": true,
        "accept-terms": true
      }
    })

    user = from(u in CodeStats.User, where: u.username == "foo") |> Repo.one!()
    assert user.email == "foo@bar"
  end

  test "signup with too short password", %{conn: conn} do
    conn =
      post(conn, "/signup", %{
        user: %{
          username: "foo",
          password: "abc",
          "not-underage": true,
          "accept-terms": true
        }
      })

    assert response(conn, 400)
  end

  test "signup with invalid email", %{conn: conn} do
    conn =
      post(conn, "/signup", %{
        user: %{
          username: "foo",
          password: "abcdefg",
          email: "arg",
          "not-underage": true,
          "accept-terms": true
        }
      })

    assert response(conn, 400)
  end
end
