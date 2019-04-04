defmodule CodeStats.Profile.PublicSchema do
  use Absinthe.Schema

  @generic_error "User not found or no access to profile."

  import_types(CodeStats.Profile.SchemaObjects)

  query do
    @desc "Get profile by username"
    field :profile, :profile do
      @desc "Username of profile"
      arg(:username, type: :string)

      resolve(fn
        # User has authenticated and so is available in the context
        %{username: username}, %{context: %{user: user}} ->
          if username == user.username do
            resolve_if_permission(user, user)
          else
            resolve_by_username(username, user)
          end

        # No authentication so check if can access profile
        %{username: username}, _ ->
          resolve_by_username(username, nil)
      end)
    end
  end

  # Resolve user by username, with authed user if exists
  defp resolve_by_username(username, authed_user) do
    case CodeStats.User.get_by_username(username) do
      %CodeStats.User{} = user ->
        resolve_if_permission(user, authed_user)

      _ ->
        {:error, @generic_error}
    end
  end

  # Resolve user data if the given authed user has permission to view their data
  defp resolve_if_permission(user, authed_user) do
    if CodeStats.Profile.PermissionUtils.can_access_profile?(authed_user, user) do
      cache = user.cache || %{}
      {:ok, %{id: user.id, cache: cache, registered: user.inserted_at}}
    else
      {:error, @generic_error}
    end
  end
end
