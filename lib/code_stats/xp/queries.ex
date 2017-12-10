defmodule XP.Queries do
  @moduledoc """
  Module to collect different query helpers. The aim is to make writing queries easy by composing helper functions.
  """

  import Ecto.Query
  require Ecto.Query

  alias CodeStats.{
    XP,
    Language,
    User
  }

  alias CodeStats.User.{Pulse, Machine}

  def init_query() do
    from(x in XP)
  end

  def since(query, dt) do
    since_q = from(p in Pulse, where: p.sent_at > ^dt)

    join(query, :inner, [x], p in ^since_q, x.pulse_id == p.id)
  end

  def by_user(query, user_id) do
    user_q = from(p in Pulse, where: p.user_id == ^user_id)

    join(query, :inner, [x], p in ^user_q, x.pulse_id == p.id)
  end

  def sum_by_language(query) do
    query
    |> group_by([x], x.language_id)
    |> select([x], {x.language_id, sum(x.amount)})
  end
end
