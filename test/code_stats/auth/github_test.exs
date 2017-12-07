defmodule CodeStats.Auth.GithubTest do
  use ExUnit.Case

  alias CodeStats.Auth.Github

  test "don't return url github login url when disabled" do
    settings = [
      enabled: false,
      client_id: "test",
      client_secret: "test"
    ]
    Application.put_env(:code_stats, Github, settings)

    assert {:error, msg} = Github.url()
    assert is_binary(msg)
  end

  test "don't return url github login url when id is nil" do
    settings = [
      enabled: true,
      client_id: nil,
      client_secret: "test"
    ]
    Application.put_env(:code_stats, Github, settings)

    assert {:error, msg} = Github.url()
    assert is_binary(msg)
  end

  test "don't return url github login url when secret is nil" do
    settings = [
      enabled: true,
      client_id: "test",
      client_secret: nil
    ]
    Application.put_env(:code_stats, Github, settings)

    assert {:error, msg} = Github.url()
    assert is_binary(msg)
  end

  test "return github login url with valid values" do
    settings = [
      enabled: true,
      client_id: "test",
      client_secret: "test"
    ]
    Application.put_env(:code_stats, Github, settings)

    assert {:ok, url} = Github.url()
    assert is_binary(url)
  end
end
