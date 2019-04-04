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
  alias CodeStats.User.Cache

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
      where: p.user_id == ^user_id and p.sent_at >= ^since and m.active == true,
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
      where: p.user_id == ^user_id and p.sent_at >= ^since,
      group_by: l.id,
      select: %{id: l.id, name: l.name, xp: sum(x.amount)}
    )
    |> Repo.all()
  end

  @doc """
  Get profile's total amount of XP per language per day since given date.
  """
  def day_languages(user_id, %Date{} = since) do
    {:ok, since_dt} = NaiveDateTime.new(since, ~T[00:00:00])

    from(
      x in XP,
      join: p in Pulse,
      on: x.pulse_id == p.id,
      join: l in Language,
      on: x.language_id == l.id,
      where: p.user_id == ^user_id and p.sent_at_local >= ^since_dt,
      group_by: [fragment("dt"), l.id],
      select: %{
        date: fragment("?::date as dt", p.sent_at_local),
        language: l.name,
        xp: sum(x.amount)
      }
    )
    |> Repo.all()
  end

  #################
  # Cache functions
  # These functions operate on the profile's cache, so they are very quick to return data.
  #################

  @doc """
  Get profile's total amount of XP from their cache.
  """
  @spec cached_total(Cache.db_t()) :: integer
  def cached_total(cache)

  def cached_total(%{"languages" => languages}) when is_map(languages) do
    languages |> Map.values() |> Enum.reduce(0, fn acc, xp -> acc + xp end)
  end

  def cached_total(_), do: 0

  @doc """
  Get profile's total languages and their XPs from cache.
  """
  @spec cached_languages(Cache.db_t()) :: [%{optional(atom) => String.t() | integer}]
  def cached_languages(cache)

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

  def cached_languages(_), do: []

  @doc """
  Get profile's total machines and their XPs from cache.
  """
  @spec cached_machines(Cache.db_t()) :: [%{optional(atom) => String.t() | integer}]
  def cached_machines(cache)

  def cached_machines(%{"machines" => machines}) when is_map(machines) do
    intkeys =
      machines
      |> Map.to_list()
      |> Enum.map(fn {k, v} -> {String.to_integer(k), v} end)
      |> Enum.into(%{})

    ids = Map.keys(intkeys)

    structs =
      from(m in Machine, where: m.id in ^ids and m.active == true, select: {m.id, m.name})
      |> Repo.all()
      |> Enum.into(%{})

    Enum.reduce(ids, [], fn id, acc ->
      if Map.has_key?(structs, id) do
        [%{name: structs[id], xp: intkeys[id]} | acc]
      else
        acc
      end
    end)
  end

  def cached_machines(_), do: []

  @doc """
  Get profile's all active dates and their XPs from cache.
  """
  @spec cached_dates(Cache.db_t()) :: [%{optional(atom) => String.t() | integer}]
  def cached_dates(cache)

  def cached_dates(%{"dates" => dates}) when is_map(dates) do
    Map.to_list(dates)
    |> Enum.map(fn {date, xp} -> %{date: date, xp: xp} end)
  end

  def cached_dates(_), do: []

  @doc """
  Get profile's active dates and their XPs since given datetime from cache.
  """
  @spec cached_dates(Cache.db_t(), Date.t()) :: [%{optional(atom) => Date.t() | integer}]
  def cached_dates(cache, since)

  def cached_dates(cache, %Date{} = since) when is_map(cache) do
    cached_dates(cache)
    |> Enum.map(fn data -> %{data | date: Date.from_iso8601!(data.date)} end)
    |> Enum.filter(fn %{date: date} -> Date.compare(date, since) != :lt end)
  end

  def cached_dates(_, _), do: []

  @doc """
  Get days of week when profile has been active and their total XPs.
  """
  @spec cached_days_of_week(Cache.db_t()) :: %{optional(Calendar.day()) => integer}
  def cached_days_of_week(cache)

  def cached_days_of_week(%{"dates" => dates}) when is_map(dates) do
    cached_dates(%{"dates" => dates})
    |> Enum.reduce(%{}, fn %{date: date, xp: xp}, acc ->
      dow_reducer(acc, date, xp)
    end)
  end

  def cached_days_of_week(_), do: []

  @doc """
  Get days of week when profile has been active and their total XPs since given date.
  """
  @spec cached_days_of_week(Cache.db_t(), Date.t()) :: %{optional(Calendar.day()) => integer}
  def cached_days_of_week(cache, since)

  def cached_days_of_week(%{"dates" => dates}, %Date{} = since) when is_map(dates) do
    cached_dates(%{"dates" => dates}, since)
    |> Enum.reduce(%{}, fn %{date: date, xp: xp}, acc ->
      dow_reducer(acc, date, xp)
    end)
  end

  def cached_days_of_week(_, _), do: []

  @doc """
  Get hours of day when profile has been active and their total XPs.
  """
  @spec cached_hours(Cache.db_t()) :: %{optional(String.t()) => integer}
  def cached_hours(cache)

  def cached_hours(cache) when is_map(cache) do
    Map.get(cache, "hours", %{})
  end

  def cached_hours(_), do: []

  defp dow_reducer(acc, date, xp) when is_map(acc) and is_binary(date) and is_integer(xp) do
    case Date.from_iso8601(date) do
      {:ok, dt} ->
        dow_reducer(acc, dt, xp)

      {:error, _} ->
        acc
    end
  end

  defp dow_reducer(acc, %Date{} = date, xp) when is_map(acc) and is_integer(xp) do
    dow = Date.day_of_week(date)
    Map.update(acc, dow, xp, &(&1 + xp))
  end
end
