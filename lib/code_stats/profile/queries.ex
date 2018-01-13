defmodule CodeStats.Profile.Queries do
  @moduledoc """
  Helper queries for profile GraphQL endpoint.
  """

  import Ecto.Query

  alias CodeStats.Repo
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
    |> Repo.all()
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
    |> Repo.all()
  end

  @doc """
  Get profile's total amount of XP from their cache.
  """
  def cached_total(%{"languages" => languages}) when is_map(languages) do
    languages |> Map.values() |> Enum.reduce(0, fn acc, xp -> acc + xp end)
  end

  #################
  # Cache functions
  # These functions operate on the profile's cache, so they are very quick to return data.
  #################

  @doc """
  Get profile's total languages and their XPs from cache.
  """
  def cached_languages(%{"languages" => languages}) when is_map(languages) do
    intkeys =
      languages
      |> Map.to_list()
      |> Enum.map(fn {k, v} -> {String.to_integer(k), v} end)
      |> Enum.into(%{})

    ids = Map.keys(intkeys)

    structs =
      from(l in Language, where: l.id in ^ids, select: {l.id, l.name})
      |> Repo.all()
      |> Enum.into(%{})

    Enum.map(ids, fn id -> %{name: structs[id], xp: intkeys[id]} end)
  end

  @doc """
  Get profile's total machines and their XPs from cache.
  """
  def cached_machines(%{"machines" => machines}) when is_map(machines) do
    intkeys =
      machines
      |> Map.to_list()
      |> Enum.map(fn {k, v} -> {String.to_integer(k), v} end)
      |> Enum.into(%{})

    ids = Map.keys(intkeys)

    structs =
      from(m in Machine, where: m.id in ^ids, select: {m.id, m.name})
      |> Repo.all()
      |> Enum.into(%{})

    Enum.map(ids, fn id -> %{name: structs[id], xp: intkeys[id]} end)
  end

  @doc """
  Get profile's all active dates and their XPs from cache.
  """
  def cached_dates(%{"dates" => dates}) when is_map(dates) do
    Map.to_list(dates)
    |> Enum.map(fn {date, xp} -> %{date: date, xp: xp} end)
  end

  @doc """
  Get profile's active dates and their XPs since given datetime from cache.
  """
  def cached_dates(cache, %Date{} = since) when is_map(cache) do
    cached_dates(cache)
    |> Enum.map(fn data -> %{data | date: Date.from_iso8601!(data.date)} end)
    |> Enum.filter(fn %{date: date} -> Date.compare(date, since) != :lt end)
  end
end
