defmodule CodeStats.ProfileController do
  use CodeStats.Web, :controller

  alias CodeStats.AuthUtils
  alias CodeStats.User
  alias CodeStats.SetSessionUser

  def my_profile(conn, _params) do
    user = SetSessionUser.get_user_data(conn)
    redirect(conn, to: profile_path(conn, :profile, user.username))
  end

  def profile(conn, %{"username" => username}) do
    case AuthUtils.get_user(username) do
      nil ->
        conn
        |> put_status(404)
        |> render(CodeStats.ErrorView, "404.html")

      %User{} = user ->
        conn
        |> assign(:user, user)
        |> render("profile.html")
    end

    render(conn, "profile.html")
  end

  def edit(conn, _params) do
    changeset = User.changeset(SetSessionUser.get_user_data(conn))
    conn
    |> common_edit_assigns()
    |> render("preferences.html", changeset: changeset)
  end

  def do_edit(conn, %{"user" => user}) do
    changeset = User.updating_changeset(SetSessionUser.get_user_data(conn), user)
    case AuthUtils.update_user(changeset) do
      %User{} ->
        conn
        |> put_flash(:success, "Preferences updated!")
        |> redirect(to: profile_path(conn, :edit))

      %Ecto.Changeset{} = error_changeset ->
        conn
        |> common_edit_assigns()
        |> put_flash(:error, "Error updating preferences.")
        |> render("preferences.html", error_changeset: error_changeset)
    end
  end

  def change_password(conn, %{"old_password" => old_password, "new_password" => new_password}) do
    user = SetSessionUser.get_user_data(conn)

    if AuthUtils.check_user_password(user, old_password) do
      password_changeset = User.password_changeset(user, %{password: new_password})
      case AuthUtils.update_user(password_changeset) do
        %User{} ->
          conn
          |> put_flash(:password_success, "Password changed.")
          |> redirect(to: profile_path(conn, :edit))

        %Ecto.Changeset{} ->
          conn
          |> put_flash(:password_error, "Error changing password.")
          |> redirect(to: profile_path(conn, :edit))
      end
    else
      conn
      |> put_flash(:password_error, "Old password was wrong!")
      |> redirect(to: profile_path(conn, :edit))
    end
  end

  def delete(conn, %{"delete_confirmation" => delete}) do
    user = SetSessionUser.get_user_data(conn)

    if delete == "DELETE" do
      case AuthUtils.delete_user(user) do
        true ->
          conn
          |> AuthUtils.unauth_user()
          |> put_flash(:info, "Your user account has been deleted.")
          |> redirect(to: page_path(conn, :index))
        false ->
          conn
          |> put_flash(:delete_error, "There was an error deleting your account.")
          |> redirect(to: profile_path(conn, :edit))
      end
    else
      conn
      |> put_flash(:delete_error, "Please confirm deletion by typing \"DELETE\" into the inpute field.")
      |> redirect(to: profile_path(conn, :edit))
    end
  end

  def regen_keys(conn, _params) do
    user = SetSessionUser.get_user_data(conn)
    api_salt_changeset = User.api_salt_changeset(user, %{})
    case AuthUtils.update_user(api_salt_changeset) do
      %User{} ->
        conn
        |> put_flash(:regen_keys_success, "API key regenerated.")
        |> redirect(to: profile_path(conn, :edit))

      %Ecto.Changeset{} ->
        conn
        |> put_flash(:regen_keys_error, "Error regenerating API key.")
        |> redirect(to: profile_path(conn, :edit))
    end
  end

  defp common_edit_assigns(conn) do
    user_data = SetSessionUser.get_user_data(conn)
    assign(conn, :user, user_data)
  end
end
