defmodule CodeStatsWeb.ConsentPlug do
  @moduledoc """
  This plug maintains the consent of users.

  The service cannot be used without consenting to certain legal terms. When a user logs in, this
  plug checks that they have consented to the latest legal terms, and if not, redirects them to
  the consent form. Resistance is futile.
  """

  def init(opts) do
    opts
  end

  @spec call(Plug.Conn.t(), Keyword.t()) :: Plug.Conn.t()
  def call(conn, _opts) do
    consent_page_path = CodeStatsWeb.Router.Helpers.terms_path(conn, :ask_consent)

    # Paths that should not be redirected from
    no_redirect_paths = [
      consent_page_path,
      CodeStatsWeb.Router.Helpers.auth_path(conn, :logout)
    ]

    with true <- CodeStatsWeb.AuthUtils.is_authed?(conn),
         %CodeStats.User{} = user <- CodeStatsWeb.AuthUtils.get_current_user(conn),
         false <- CodeStats.LegalTerms.is_current_version?(user.terms_version),
         false <- conn.request_path in no_redirect_paths do
      conn
      |> Phoenix.Controller.redirect(to: consent_page_path)
      |> Plug.Conn.halt()
    else
      _ -> conn
    end
  end
end
