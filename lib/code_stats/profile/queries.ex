defmodule CodeStats.Profile.Queries do
  @moduledoc """
  Helper queries for profile GraphQL endpoint. These functions only return queries, that should be run through the Repo
  in the calling module.
  """

  import Ecto.Query

  alias CodeStats.XP
  alias CodeStats.Language
  alias CodeStats.User.Pulse
  alias CodeStats.User.Machine

  @doc """
  Get total XPs per machine since given datetime.
  """
  def machine_xps(user_id, %DateTime{} = since) do
    from(
      x in XP,
      join: p in Pulse,
      on: x.pulse_id == p.id,
      join: m in Machine,
      on: p.machine_id == m.id,
      where: p.sent_at > ^since and p.user_id == ^user_id,
      group_by: m.id,
      select: %{id: m.id, name: m.name, xp: sum(x.amount)}
    )
  end

  @doc """
  Get total XPs per language since given datetime.
  """
  def language_xps(user_id, %DateTime{} = since) do
    from(
      x in XP,
      join: p in Pulse,
      on: x.pulse_id == p.id,
      join: l in Language,
      on: x.language_id == l.id,
      where: p.sent_at > ^since and p.user_id == ^user_id,
      group_by: l.id,
      select: %{id: l.id, name: l.name, xp: sum(x.amount)}
    )
  end
end
