defmodule CodeStats.UserHelpers do
  @moduledoc """
  Test helpers for user related tests.
  """

  alias CodeStats.{User, Repo}

  def create_user(email, username, password \\ "test_password") do
    %User{}
    |> User.changeset(%{
      email: email,
      username: username,
      password: password,
      terms_version: CodeStats.LegalTerms.get_latest_version()
    })
    |> Repo.insert()
  end

  def force_login(conn, user) do
    Plug.Test.init_test_session(conn, %{CodeStatsWeb.AuthUtils.auth_key() => user.id})
  end
end
