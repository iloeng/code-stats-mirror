defmodule CodeStats.Auth.Github do
  @moduledoc """
  OAuth2 GitHub Provider

  ## How to setup auth on GitHub

  1. Go to https://github.com/settings/developers
  2. Click "New OAuth App" button on top right
  3. Add name and description you like, example "codestats development"
  4. Add homepage url
    - http://localhost:5000 for development
    - https://codestats.net for production
  5. Add authorization callback url
    - http://localhost:5000/login/oauth/github for development
    - https://codestats.net/login/oauth/github for production

  ## Config

  ```
  config :code_stats, CodeStats.Auth.Github,
    enabled: true,
    client_id: System.get_env("GITHUB_APP_ID"),
    client_secret: System.get_env("GITHUB_APP_SECRET")
  ```

  ## Usage

  ##### Get authorization url
  ```
  <%= if {:ok, url} == CodeStats.Auth.Github.url() do %>
    <a href="<%= url %>">GitHub login</a>
  <% end %>
  ```

  ##### Get user info
  ```
  # Code is returned from github authentication
  # See CodeStatsWeb.AuthController for example
  if {:ok, user} == CodeStats.Auth.Github.user(code: "code from github") do
    # Save user info or login user...
  end
  ```
  """
  use OAuth2.Strategy

  alias OAuth2.Client
  alias OAuth2.Strategy.AuthCode

  @client_defaults [
    enabled: false,
    client_id: nil,
    client_secret: nil,
    strategy: __MODULE__,
    site: "https://api.github.com",
    authorize_url: "https://github.com/login/oauth/authorize",
    token_url: "https://github.com/login/oauth/access_token"
  ]

  @doc """
  Get url for authorizing user
  """
  @spec url(keyword, keyword) :: {:ok, String.t} | {:error, String.t}
  def url(params \\ [], opts \\ []) do
    case get_client(opts) do
      {:ok, client} ->
        {:ok, Client.authorize_url!(client, params)}

      {:error, msg} ->
        {:error, msg}
    end
  end

  # Get token to client
  defp token(params, opts) when is_list(params) and is_list(opts) do
    headers = Keyword.get(opts, :headers, [])
    options = Keyword.get(opts, :options, [])

    case get_client(opts) do
      {:ok, client} ->
        {:ok, Client.get_token!(client, params, headers, options)}

      {:error, msg} ->
        {:error, msg}
    end
  end

  @doc """
  Returns user information only.
  To return token before querying for user, see `get_user/3`
  """
  @spec user(keyword, keyword) :: map
  def user(params \\ [], opts \\ []) do
    with {:ok, client} <- token(params, opts),
         {:ok, %{status_code: 200, body: body}} <- Client.get(client, "/user")
    do
      {:ok, body}
    end
  end

  # Generate client for OAuth2 requests
  @spec get_client(keyword) :: {:ok, Client.t} | {:error, String.t}
  defp get_client(opts) do
    config = Application.get_env(:code_stats, __MODULE__, [])
    opts =
      opts
      |> Enum.into(config)
      |> Enum.into(@client_defaults)

    # Check for disabled or missing
    case Enum.into(opts, %{}) do
      %{enabled: false} ->
        {:error, "Github authentication disabled"}

      %{client_id: nil} ->
        {:error, "Github authentication missing client_id"}

      %{client_secret: nil} ->
        {:error, "Github authentication missing client_secret"}

      _ ->
        {:ok, Client.new(opts)}
    end
  end

  # Strategy Callbacks

  def authorize_url(client, params) do
    AuthCode.authorize_url(client, params)
  end

  def get_token(client, params, headers) do
    client
    |> put_param(:client_secret, client.client_secret)
    |> put_header("Accept", "application/json")
    |> AuthCode.get_token(params, headers)
  end

  @doc """
  Returns user information from GitHub's `/user` and `/user/emails` endpoints using the access_token.
  """
  @spec get_user(%Client{}) :: {:ok, map} | {:error, String.t}
  def get_user(client) do
    case OAuth2.Client.get(client, "/user") do
      {:ok, %OAuth2.Response{status_code: 401, body: _body}} ->
        {:error, "Unauthorized"}
      {:ok, %OAuth2.Response{status_code: status_code, body: body}}
        when status_code in 200..399 ->
        {:ok, body}
      {:error, %OAuth2.Error{reason: reason}} ->
        {:error, reason}
    end
  end
end
