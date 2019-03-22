defmodule CodeStats.User.CacheUtils do
  @moduledoc """
  Utilities for user's cache generation and updating.
  """

  require Logger

  import Ecto.Query, only: [from: 2]

  alias Ecto.Changeset
  alias CodeStats.Repo
  alias CodeStats.User.{Pulse, Cache}
  alias CodeStats.XP

  @doc """
  Calculate and store cached XP values for user, using all historical data to reset the cache.
  """
  @spec update_all!(User.t()) :: :ok
  def update_all!(user) do
    # Don't use any previous cache data
    empty_cache = %{}
    all_since = DateTime.from_naive!(~N[1970-01-01T00:00:00], "Etc/UTC")

    # Load all of user's new XP plus required associations
    xps =
      from(
        x in XP,
        join: p in Pulse,
        on: p.id == x.pulse_id,
        where: p.user_id == ^user.id and p.inserted_at >= ^all_since,
        select: {p, x}
      )
      |> Repo.all()
      |> case do
        nil -> []
        ret -> ret
      end

    operation = fn cache ->
      Enum.reduce(xps, cache, fn {pulse, xp}, acc ->
        update_cache_from_xp(
          acc,
          try_sent_at_local(pulse),
          xp.language_id,
          pulse.machine_id,
          xp.amount
        )
      end)
    end

    cache = update(empty_cache, operation, true)

    # Persist cache changes and update user's last cached timestamp
    cset = Changeset.cast(user, %{cache: cache}, [:cache])
    {:ok, _} = Repo.update(cset)
    :ok
  end

  @doc """
  Update given user cache (from DB) with the updater operation, set the caching duration, and then
  return the data in DB format for persisting back.
  """
  @spec update(Cache.db_t() | nil, (Cache.t() -> Cache.t()), boolean) :: Cache.db_t()
  def update(cache, operation, is_total)

  # Protect from nil user cache (new user, first pulse?)
  def update(nil, operation, is_total), do: update(%{}, operation, is_total)

  def update(cache, operation, is_total)
      when is_map(cache) and is_function(operation, 1) and is_boolean(is_total) do
    update_start_time = DateTime.utc_now()
    duration_key = if is_total, do: "total_caching_duration", else: "caching_duration"

    unformat_cache_from_db(cache)
    |> operation.()
    |> format_cache_for_db()
    |> Map.put(duration_key, get_caching_duration(update_start_time))
  end

  @doc """
  Update user's cache with the given details and list of XPs. Returns the updated cache.
  """
  @spec update_cache_from_xps(Cache.t(), NaiveDateTime.t() | DateTime.t(), integer, [
          %{language_id: integer, amount: integer}
        ]) :: Cache.t()
  def update_cache_from_xps(%Cache{} = cache, datetime, machine_id, xps)
      when is_integer(machine_id) and is_list(xps) do
    Enum.reduce(
      xps,
      cache,
      &update_cache_from_xp(&2, datetime, &1.language_id, machine_id, &1.amount)
    )
  end

  @doc """
  Update user's cache with the given details. Returns the updated cache.
  """
  @spec update_cache_from_xp(
          Cache.t(),
          NaiveDateTime.t() | DateTime.t(),
          integer,
          integer,
          integer
        ) :: Cache.t()
  def update_cache_from_xp(
        %Cache{} = cache,
        datetime,
        language_id,
        machine_id,
        amount
      )
      when is_integer(language_id) and is_integer(machine_id) and is_integer(amount) do
    # Date could be a DateTime for old XPs
    date =
      case datetime do
        %NaiveDateTime{} -> NaiveDateTime.to_date(datetime)
        %DateTime{} -> DateTime.to_date(datetime)
      end

    languages = Map.update(cache.languages, language_id, amount, &(&1 + amount))
    machines = Map.update(cache.machines, machine_id, amount, &(&1 + amount))
    dates = Map.update(cache.dates, date, amount, &(&1 + amount))
    hours = Map.update(cache.hours, datetime.hour, amount, &(&1 + amount))

    %{cache | languages: languages, machines: machines, dates: dates, hours: hours}
  end

  @doc """
  Unformat data from DB to native datatypes
  """
  @spec unformat_cache_from_db(Cache.db_t()) :: Cache.t()
  def unformat_cache_from_db(cache) do
    languages =
      Map.get(cache, "languages", %{})
      |> str_keys_to_int()

    machines =
      Map.get(cache, "machines", %{})
      |> str_keys_to_int()

    dates =
      Map.get(cache, "dates", %{})
      |> Map.to_list()
      |> Enum.map(fn {key, value} -> {Date.from_iso8601!(key), value} end)
      |> Map.new()

    hours =
      Map.get(cache, "hours", %{})
      |> Map.to_list()
      |> Enum.map(fn {key, value} -> {String.to_integer(key), value} end)
      |> Map.new()

    %Cache{
      languages: languages,
      machines: machines,
      dates: dates,
      hours: hours,
      caching_duration: Map.get(cache, "caching_duration", 0.0),
      total_caching_duration: Map.get(cache, "total_caching_duration", 0.0)
    }
  end

  # Format data in cache for storing into DB as JSON
  @spec format_cache_for_db(Cache.t()) :: Cache.db_t()
  defp format_cache_for_db(cache) do
    languages = int_keys_to_str(cache.languages)

    machines = int_keys_to_str(cache.machines)

    dates =
      cache.dates
      |> Map.to_list()
      |> Enum.map(fn {key, value} -> {Date.to_iso8601(key), value} end)
      |> Map.new()

    hours =
      cache.hours
      |> Map.to_list()
      |> Enum.map(fn {key, value} -> {Integer.to_string(key), value} end)
      |> Map.new()

    %{
      "languages" => languages,
      "machines" => machines,
      "dates" => dates,
      "hours" => hours,
      "caching_duration" => cache.caching_duration,
      "total_caching_duration" => cache.total_caching_duration
    }
  end

  @spec int_keys_to_str(%{optional(integer) => any}) :: %{optional(String.t()) => any}
  defp int_keys_to_str(map) do
    map
    |> Map.to_list()
    |> Enum.map(fn {key, value} -> {Integer.to_string(key), value} end)
    |> Map.new()
  end

  @spec str_keys_to_int(%{optional(String.t()) => any}) :: %{optional(integer) => any}
  defp str_keys_to_int(map) do
    map
    |> Map.to_list()
    |> Enum.map(fn {key, value} -> {Integer.parse(key) |> elem(0), value} end)
    |> Map.new()
  end

  @spec get_caching_duration(DateTime.t()) :: float
  defp get_caching_duration(start_time) do
    Calendar.DateTime.diff(DateTime.utc_now(), start_time)
    |> (fn {:ok, s, us, _} -> s + us / 1_000_000 end).()
  end

  # Try using local sent_at time if available, fall back on more inaccurate sent_at
  @spec try_sent_at_local(Pulse.t()) :: DateTime.t() | NaiveDateTime.t()
  defp try_sent_at_local(%Pulse{} = pulse) do
    case pulse.sent_at_local do
      %NaiveDateTime{} = dt -> dt
      nil -> pulse.sent_at
    end
  end
end
