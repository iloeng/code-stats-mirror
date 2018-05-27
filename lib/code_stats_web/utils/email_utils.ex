defmodule CodeStatsWeb.EmailUtils do
  @moduledoc """
  Utilities related to sending different emails from the system.
  """

  use Bamboo.Phoenix, view: CodeStatsWeb.EmailView

  alias CodeStats.{
    User,
    Mailer
  }

  @doc """
  Send password reset email with the given token to the given user.

  NOTE: User must have an email! Check before calling this function.
  """
  @spec send_password_reset_email(%User{}, String.t()) :: Bamboo.Email.t()
  def send_password_reset_email(%User{email: email}, token) do
    CodeStats.EmailUtils.base_email()
    |> to(email)
    |> subject("Code::Stats password reset request")
    |> assign(:token, token)
    |> put_layout({CodeStatsWeb.LayoutView, :email})
    |> render(:password_reset)
    |> Mailer.deliver_later()
  end
end
