defmodule CodeStatsWeb.AuthController do
  use CodeStatsWeb, :controller

  alias Calendar.DateTime, as: CDateTime

  alias CodeStatsWeb.AuthUtils
  alias CodeStatsWeb.EmailUtils
  alias CodeStatsWeb.RememberMePlug
  alias CodeStats.Repo
  alias CodeStats.User
  alias CodeStats.User.PasswordReset
  alias CodeStats.Auth.Github

  def render_login(conn, _params) do
    conn
    |> assign(:title, "Login")
    |> render("login.html")
  end

  def render_signup(conn, _params) do
    changeset = User.changeset(%User{})

    conn
    |> assign(:title, "Signup")
    |> render("signup.html", changeset: changeset)
  end

  def oauth(conn, %{"app" => "github", "code" => code}) do
    with {:ok, body} <- Github.user(code: code),
         {user = %User{}, _} <- {AuthUtils.get_user(body["login"], from: "github"), body}
    do
      conn
      |> AuthUtils.force_auth_user_id(user.id)
      |> redirect(to: profile_path(conn, :my_profile))
    else
      # Missing user, try to create it and login with that user
      {nil, body} ->
        params = %{
          username: body["login"],
          password: "github",
          email: body["email"],
          from: "github",
        }
        case Repo.insert(User.changeset(%User{}, params)) do
          {:ok, user} ->
            conn
            |> AuthUtils.force_auth_user_id(user.id)
            |> put_flash(:success, "Great success! Your account was created and you can now log in with GitHub.")
            |> redirect(to: profile_path(conn, :my_profile))

          {:error, _} ->
            conn
            |> assign(:title, "Login")
            |> put_flash(:error, "Failed to login with GitHub")
            |> render("login.html")
        end

      _ret ->
        conn
        |> assign(:title, "Login")
        |> put_flash(:error, "Failed to login with GitHub")
        |> render("login.html")
    end
  end

  def login(conn, %{"username" => username, "password" => password} = params) do
    with %User{} = user      <- AuthUtils.get_user(username, case_insensitive: true),
         %Plug.Conn{} = conn <- AuthUtils.auth_user(conn, user, password),
         %Plug.Conn{} = conn <- maybe_remember_me(conn, user, params) do
      redirect(conn, to: profile_path(conn, :my_profile))
    else
      ret ->
        # If ret is nil, user was not found -> run dummy auth to prevent user enumeration
        # But they can enumerate with the signin form anyway lol
        # TODO: Add CAPTCHA to signup form
        if ret == nil, do: AuthUtils.dummy_auth_user()

        conn
        |> assign(:title, "Login")
        |> assign(:username_input, username)
        |> put_status(404)
        |> put_flash(:error, "Wrong username and/or password!")
        |> render("login.html")
    end
  end

  def signup(conn, %{"user" => user_params}) do
    %User{}
    |> User.changeset(Map.put(user_params, "from", "codestats"))
    |> AuthUtils.create_user()
    |> case do
      %Ecto.Changeset{} = changeset ->
        conn
        |> assign(:title, "Signup")
        |> put_status(400)
        |> render("signup.html", changeset: changeset)

      %User{} ->
        conn
        |> put_flash(
          :success,
          "Great success! Your account was created and you can now log in with the details you provided."
        )
        |> redirect(to: auth_path(conn, :render_login))
    end
  end

  def logout(conn, _params) do
    conn
    |> AuthUtils.unauth_user()
    |> RememberMePlug.kill_cookie()
    |> redirect(to: page_path(conn, :index))
  end

  def render_forgot(conn, _params) do
    {changeset, _} = PasswordReset.changeset(%PasswordReset{})

    conn
    |> assign(:title, "Forgot password")
    |> render("forgot.html", changeset: changeset)
  end

  def forgot(conn, %{"password_reset" => params}) do
    {changeset, user} = PasswordReset.changeset(%PasswordReset{}, params)

    # If the changeset is valid, attempt to create password reset token
    # and send email
    with true <- changeset.valid?,
         %PasswordReset{token: token} <- Repo.insert!(changeset) do
      EmailUtils.send_password_reset_email(user, token)
    else
      _ -> nil
    end

    conn
    |> put_flash(
      :info,
      "A password reset email will be sent shortly to the email address linked to the account, if the account had one. If you do not receive an email, please check that you typed the account name correctly."
    )
    |> redirect(to: auth_path(conn, :render_forgot))
  end

  def render_reset(conn, %{"token" => token}) do
    case check_reset_token(token) do
      %PasswordReset{} = persisted_token ->
        changeset = User.password_changeset(persisted_token.user, %{})

        conn
        |> assign(:title, "Password reset")
        |> assign(:token, persisted_token.token)
        |> render("reset.html", changeset: changeset)

      nil ->
        conn
        |> put_status(404)
        |> render(CodeStatsWeb.ErrorView, "error_404.html")
    end
  end

  def reset(conn, %{"user" => params, "token" => token}) do
    with %PasswordReset{} = token <- check_reset_token(token),
         changeset = User.password_changeset(token.user, params),
         %User{} <- Repo.update!(changeset) do
      Repo.delete(token)

      conn
      |> put_flash(
        :success,
        "Password reset successfully. You can now log in with the new password."
      )
      |> redirect(to: auth_path(conn, :render_login))
    else
      _ ->
        conn
        |> put_flash(
          :error,
          "Unable to reset password. The password reset token may have expired. Please try requesting a new token."
        )
        |> redirect(to: auth_path(conn, :render_login))
    end
  end

  # Check that reset token exists and is valid, and return the reset token with the user
  # preloaded or nil if not found
  defp check_reset_token(token) do
    now = DateTime.utc_now()
    earliest_valid = CDateTime.subtract!(now, PasswordReset.token_max_life() * 3600)

    query =
      from(
        p in PasswordReset,
        where: p.token == ^token and p.inserted_at >= ^earliest_valid,
        preload: [:user]
      )

    case Repo.one(query) do
      %PasswordReset{} = token -> token
      nil -> nil
    end
  end

  defp maybe_remember_me(conn, user, %{"remember-me" => _}) do
    RememberMePlug.write_cookie(conn, user)
  end

  defp maybe_remember_me(conn, _, _), do: conn
end
