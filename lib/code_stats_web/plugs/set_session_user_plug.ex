defmodule CodeStatsWeb.SetSessionUserPlug do
  @moduledoc """
  This module sets the data of the current session authenticated user into the conn.

  is_authed? should be used to check if user data is available before using the data set by
  this plug.

  This plug also adds the user status for use in Absinthe.
  """

  import Plug.Conn
  import Ecto.Query, only: [from: 2]

  alias CodeStatsWeb.AuthUtils
  alias CodeStats.Repo
  alias CodeStats.User

  def init(opts) do
    opts
  end

  def call(conn, _opts) do
    if AuthUtils.is_authed?(conn) do
      id = AuthUtils.get_current_user_id(conn)
      query = from(u in User, where: u.id == ^id)
      user = Repo.one(query)

      conn
      |> put_private(AuthUtils.private_info_key(), user)
      |> put_private(:absinthe, %{context: %{user: user}})
    else
      put_private(conn, AuthUtils.private_info_key(), nil)
    end
  end
end
