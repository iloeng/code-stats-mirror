defmodule CodeStatsWeb.PreferencesController do
  use CodeStatsWeb, :controller

  alias CodeStats.User
  alias CodeStatsWeb.AuthUtils

  require Logger

  plug(:set_title)

  @spec edit(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def edit(conn, _params) do
    changeset = User.updating_changeset(AuthUtils.get_current_user(conn))

    conn
    |> common_edit_assigns()
    |> render("preferences.html", changeset: changeset)
  end

  @doc """
  Common action for all editing calls: currently preferences and passwords.

  The body is chosen by the given hidden field.
  """
  @spec do_edit(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def do_edit(conn, params)

  # Edit case for editing user's information (w/o password)
  def do_edit(conn, %{"user" => %{"type" => "edit"} = user}) do
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
        |> render("preferences.html", changeset: error_changeset)
    end
  end

  # Edit case for editing user's password
  def do_edit(conn, %{
        "user" =>
          %{
            "type" => "password",
            "old_password" => old_password,
            "password" => _
          } = params
      }) do
    user = AuthUtils.get_current_user(conn)
    password_changeset = User.password_changeset(user, params)

    with {:old_pass, true} <- {:old_pass, AuthUtils.check_user_password(user, old_password)},
         {:updated, %User{}} <- {:updated, AuthUtils.update_user(password_changeset)} do
      conn
      |> put_flash(:success, "Password changed.")
      |> redirect(to: Routes.preferences_path(conn, :edit))
    else
      err ->
        error_changeset = get_password_error_cset(err, password_changeset)

        conn
        |> common_edit_assigns()
        |> put_flash(:error, "Error changing password.")
        |> render("preferences.html", pass_changeset: error_changeset)
    end
  end

  # Edit case for any other data, just return an error.
  def do_edit(conn, _params) do
    conn
    |> common_edit_assigns()
    |> put_flash(:error, "Unknown error in preferences.")
    |> render("preferences.html")
  end

  @doc """
  Action for deleting user and all their information from system.
  """
  @spec delete(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def delete(conn, params) do
    AuthUtils.delete_user_action(conn, params, {&Routes.preferences_path/2, :edit})
  end

  defp get_password_error_cset({:old_pass, false}, orig_changeset) do
    # We need to add an action to the changeset so that Phoenix will display the error,
    # otherwise it will think the changeset was not processed (as it has not been passed
    # to any Repo call) and will not show the errors
    %{orig_changeset | action: :update}
    |> Ecto.Changeset.add_error(:old_password, "does not match your current password")
  end

  defp get_password_error_cset({:updated, cset}, _), do: cset

  # Common edit assigns, including empty changesets that will be overridden in specific clauses
  defp common_edit_assigns(conn) do
    user_data = AuthUtils.get_current_user(conn)

    conn
    |> assign(:user, user_data)
    |> assign(:changeset, User.updating_changeset(AuthUtils.get_current_user(conn)))
    |> assign(:pass_changeset, User.password_changeset(AuthUtils.get_current_user(conn)))
  end

  defp set_title(conn, _opts) do
    assign(conn, :title, "Preferences")
  end
end
