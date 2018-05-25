defmodule CodeStatsWeb.TermsController do
  use CodeStatsWeb, :controller

  require Logger

  alias CodeStatsWeb.AuthUtils

  @doc """
  Display legal terms and ask for user consent.
  """
  @spec ask_consent(Plug.Conn.t(), map) :: Plug.Conn.t()
  def ask_consent(conn, _params) do
    user = AuthUtils.get_current_user(conn)
    {_, diff} = CodeStats.LegalTerms.by_date(user.terms_version)

    conn
    |> assign(:diff, diff)
    |> assign(:title, "Consent required")
    |> render("consent_page.html")
  end

  @doc """
  Accept the current legal terms and mark down their version.
  """
  @spec set_consent(Plug.Conn.t(), map) :: Plug.Conn.t()
  def set_consent(conn, %{"accept-terms" => _, "not-underage" => _}) do
    user = AuthUtils.get_current_user(conn)

    case CodeStats.User.update_terms_version(user) do
      :ok ->
        conn
        |> put_flash(:success, "You have accepted the new legal terms.")
        |> redirect(to: profile_path(conn, :my_profile))

      val ->
        Logger.error("Error storing consent: #{inspect(val)}")

        conn
        |> put_flash(
          :error,
          "There was an error storing your acceptance. If it persists, please contact the administrator."
        )
        |> ask_consent(%{})
    end
  end

  def set_consent(conn, params) do
    Logger.error("Setting consent got wrong params #{inspect(params)}")

    conn
    |> put_flash(:error, "You must check the acceptance checkboxes to accept the terms.")
    |> ask_consent(params)
  end

  @doc """
  Delete user's account as they cannot accept the terms.
  """
  @spec delete_account(Plug.Conn.t(), map) :: Plug.Conn.t()
  def delete_account(conn, params) do
    AuthUtils.delete_user_action(conn, params, {&terms_path/2, :ask_consent})
  end
end
