defmodule CodeStats.Profile.PermissionUtils do
  @moduledoc """
  Utility functions related to profile permissions.
  """

  alias CodeStats.User

  @doc """
  Can the given user access the target's profile? They can if the profile is public or
  if they are the same user as the target user. Use nil as user to signify unauthenticated
  users.

  ## Examples

      iex> CodeStats.Profile.PermissionUtils.can_access_profile?(nil, %CodeStats.User{private_profile: true})
      false

      iex> CodeStats.Profile.PermissionUtils.can_access_profile?(nil, %CodeStats.User{private_profile: false})
      true

      iex> CodeStats.Profile.PermissionUtils.can_access_profile?(%CodeStats.User{id: 1}, %CodeStats.User{id: 2, private_profile: true})
      false

      iex> CodeStats.Profile.PermissionUtils.can_access_profile?(%CodeStats.User{id: 1}, %CodeStats.User{id: 1, private_profile: true})
      true
  """
  @spec can_access_profile?(%User{} | nil, %User{}) :: boolean
  def can_access_profile?(user, target) do
    not target.private_profile or (user != nil and user.id == target.id)
  end
end
