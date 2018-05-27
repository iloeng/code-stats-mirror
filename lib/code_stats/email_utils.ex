defmodule CodeStats.EmailUtils do
  @moduledoc """
  Utilities for sending emails.
  """

  alias CodeStats.{Utils, Mailer, User}
  alias Bamboo.Email

  @doc """
  Get a base email with the appropriate sender and reply addresses.
  """
  @spec base_email() :: Email.t()
  def base_email() do
    Email.new_email()
    |> Email.from(Utils.get_conf(:email_from))
    |> Email.put_header("Reply-To", Utils.get_conf(:reply_to))
  end

  @doc """
  Send mass mail to a list of recipients.

  `subject` is the email subject line to set.

  `plaintext_file` and `html_file` are paths to plaintext and HTML versions of the email to send,
  respectively. If `html_file` is `nil`, an HTML version of the message is not included. A
  plaintext version must always exist.

  The email files are evaluated using EEx, and the username and email address will be available
  as bindings `username` and `email` respectively, example: `Dear <%= @username %>`. You can also
  call any project modules normally.

  Users must be given as a list of tuples where the first element is the username and the second
  element is the email address of that user.
  If list of users is not given, will send to all users that have an email stored in the system.

  If `dry_run` is set to true, an example email and list of recipients is printed instead of
  sending the emails.
  """
  @spec mass_mail(
          String.t(),
          String.t(),
          String.t() | nil,
          [{String.t(), String.t()}] | nil,
          boolean
        ) :: :ok | no_return()
  def mass_mail(subject, plaintext_file, html_file, users \\ nil, dry_run \\ true) do
    users = if not is_nil(users), do: users, else: User.get_all_with_email()

    plain_template = File.read!(plaintext_file)
    html_template = if not is_nil(html_file), do: File.read!(html_file), else: nil

    if dry_run do
      mass_mail_dry_run(subject, plain_template, html_template, users)
    else
      mass_mail_send(subject, plain_template, html_template, users)
    end
  end

  @doc """
  Print out statistics about what would be sent if this was a real email sending situation.
  """
  @spec mass_mail_dry_run(String.t(), String.t(), String.t() | nil, [{String.t(), String.t()}]) ::
          :ok
  def mass_mail_dry_run(subject, plain_template, html_template, users) do
    first = Enum.at(users, 0)

    email = mass_mail_form(first, subject, plain_template, html_template)

    IO.puts("DRY RUN SENDING EMAIL")
    IO.inspect(email)

    IO.puts("WOULD SEND TO FOLLOWING #{Enum.count(users)} USERS")
    IO.inspect(users)
  end

  @doc """
  Process the given templates and send an email to all of the users in the users list.
  """
  @spec mass_mail_send(String.t(), String.t(), String.t() | nil, [{String.t(), String.t()}]) ::
          :ok
  def mass_mail_send(subject, plain_template, html_template, users) do
    IO.puts("Sending...")

    Enum.each(users, fn user ->
      email = mass_mail_form(user, subject, plain_template, html_template)
      Mailer.deliver_now(email)
      IO.write(".")
    end)

    IO.puts("")
    IO.puts("Sent to #{Enum.count(users)} users.")
  end

  @doc """
  Form a new mass mail email from the given arguments.
  """
  @spec mass_mail_form({String.t(), String.t()}, String.t(), String.t(), String.t() | nil) ::
          Email.t()
  def mass_mail_form(user, subject, plain_template, html_template) do
    plain_body = process_template(plain_template, user)

    email =
      base_email()
      |> Email.to(user)
      |> Email.subject(subject)
      |> Email.text_body(plain_body)

    if not is_nil(html_template) do
      Email.html_body(email, process_template(html_template, user))
    else
      email
    end
  end

  @doc """
  Process plaintext or HTML template with the given user's data.
  """
  @spec process_template(String.t(), {String.t(), String.t()}) :: String.t()
  def process_template(template_string, {username, address}) do
    EEx.eval_string(template_string, assigns: [username: username, email: address])
  end
end
