defmodule CodeStats.User.AuthCredentials do
  use Ecto.Schema

  schema "auth_credentials" do
    field(:from, :string)
  end
end
