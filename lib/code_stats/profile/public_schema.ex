defmodule CodeStats.Profile.PublicSchema do
  use Absinthe.Schema
  import Ecto.Query, only: [from: 2]

  import_types(CodeStats.Profile.SchemaObjects)

  query do
    @desc "Get profile by username"
    field :profile, :profile do
      @desc "Username of profile"
      arg(:username, type: :string)

      resolve(fn %{username: username}, _ ->
        # TODO: Check if profile is private and user is allowed access
        get_user_data(username)
      end)
    end
  end

  defp get_user_data(username) do
    query =
      from(
        u in CodeStats.User,
        where: fragment("lower(?)", ^username) == fragment("lower(?)", u.username),
        select: %{id: u.id, username: u.username, cache: u.cache, registered: u.inserted_at}
      )

    case CodeStats.Repo.one(query) do
      nil -> {:error, "User not found"}
      user -> {:ok, user}
    end
  end
end
