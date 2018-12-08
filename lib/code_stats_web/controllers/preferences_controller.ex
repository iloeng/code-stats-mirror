defmodule CodeStatsWeb.PreferencesController do
  use CodeStatsWeb, :controller

  alias CodeStats.User
  alias CodeStatsWeb.AuthUtils

  plug(:set_title)

  def edit(conn, _params) do
    changeset = User.updating_changeset(AuthUtils.get_current_user(conn))

    conn
    |> common_edit_assigns()
    |> render("preferences.html", changeset: changeset)
  end

  def do_edit(conn, %{"user" => user}) do
    changeset = User.updating_changeset(AuthUtils.get_current_user(conn), user)

    case AuthUtils.update_user(changeset) do
      %User{} ->
        conn
        |> put_flash(:success, "Preferences updated!")
        |> redirect(to: Routes.preferences_path(conn, :edit))

      %Ecto.Changeset{} = error_changeset ->
        conn
        |> common_edit_assigns()
        |> put_flash(:error, "Error updating preferences.")
        |> render("preferences.html", error_changeset: error_changeset)
    end
  end

  def change_password(conn, %{"old_password" => old_password, "new_password" => new_password}) do
    user = AuthUtils.get_current_user(conn)

    if AuthUtils.check_user_password(user, old_password) do
      password_changeset = User.password_changeset(user, %{password: new_password})

      case AuthUtils.update_user(password_changeset) do
        %User{} ->
          conn
          |> put_flash(:success, "Password changed.")
          |> redirect(to: Routes.preferences_path(conn, :edit))

        %Ecto.Changeset{} ->
          conn
          |> put_flash(:error, "Error changing password.")
          |> redirect(to: Routes.preferences_path(conn, :edit))
      end
    else
      conn
      |> put_flash(:error, "Old password was wrong!")
      |> redirect(to: Routes.preferences_path(conn, :edit))
    end
  end

  @doc """
  Deletes user's account.
  """
  @spec delete(Plug.Conn.t(), map) :: Plug.Conn.t()
  def delete(conn, params) do
    AuthUtils.delete_user_action(conn, params, {&Routes.preferences_path/2, :edit})
  end

  defp common_edit_assigns(conn) do
    user_data = AuthUtils.get_current_user(conn)

    conn
    |> assign(:user, user_data)
  end

  defp set_title(conn, _opts) do
    assign(conn, :title, "Preferences")
  end
end
