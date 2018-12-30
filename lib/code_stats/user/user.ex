defmodule CodeStats.User do
  use Ecto.Schema

  require Logger

  import Ecto.Changeset
  import Ecto.Query

  alias Comeonin.Bcrypt

  alias CodeStats.Repo
  alias CodeStats.User.Pulse
  alias CodeStats.XP

  schema "users" do
    field(:username, :string)
    field(:email, :string)
    field(:password, :string)
    field(:last_cached, :utc_datetime)
    field(:private_profile, :boolean)
    field(:cache, :map)

    # The latest version of the legal terms that was accepted by the user
    field(:terms_version, :date)

    has_many(:pulses, Pulse)

    timestamps(type: :utc_datetime)
  end

  @doc """
  Get a changeset based on the `data` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(data, params \\ %{}) do
    data
    |> cast(params, [:username, :password, :email, :terms_version])
    |> validate_required([:username, :password, :terms_version])
    |> put_change(:private_profile, false)
    |> validate_length(:username, min: 1, max: 64)
    |> validate_length(:email, min: 1, max: 255)
    |> validate_length(:password, min: 6, max: 255)
    |> validate_format(:username, ~r/^[^\/#%?&=+]+$/)
    |> validate_latest_terms()
    |> common_validations()
    |> unique_constraint(:username)
    |> unique_constraint(:lower_username)
    |> update_change(:password, &hash_password/1)
  end

  @doc """
  Get changeset for updating a user's data.
  """
  def updating_changeset(data, params \\ %{}) do
    data
    |> cast(params, [:email, :private_profile])
    |> common_validations()
  end

  @doc """
  Get a changeset for changing a user's password.
  """
  def password_changeset(data, params \\ %{}) do
    data
    |> cast(params, [:password])
    |> validate_required([:password])
    |> update_change(:password, &hash_password/1)
  end

  @doc """
  Get a changeset for updating user's latest accepted legal terms.
  """
  @spec terms_changeset(map, map) :: Ecto.Changeset.t()
  def terms_changeset(data, params \\ %{}) do
    data
    |> cast(params, [:terms_version])
    |> validate_required([:terms_version])
    |> validate_latest_terms()
  end

  @doc """
  Get all users in the system that have an email address. Returned as a list of tuples where the
  first element is the username and the second element is the email address.
  """
  @spec get_all_with_email() :: [{String.t(), String.t()}]
  def get_all_with_email() do
    from(
      u in __MODULE__,
      where: not is_nil(u.email) and u.email != "",
      select: {u.username, u.email}
    )
    |> Repo.all()
  end

  @doc """
  Update user's accepted legal terms version to the latest available.
  """
  @spec update_terms_version(%__MODULE__{}) :: :ok | {:error, [{atom, Ecto.Changeset.error()}]}
  def update_terms_version(%__MODULE__{} = user) do
    cset = terms_changeset(user, %{terms_version: CodeStats.LegalTerms.get_latest_version()})

    case Repo.update(cset) do
      {:ok, _} -> :ok
      {:error, %Ecto.Changeset{} = err_cset} -> {:error, err_cset.errors}
    end
  end

  @doc """
  Get user with the given username.

  If second argument is true, case insensitive search is used instead.

  Returns nil if user was not found.
  """
  @spec get_by_username(String.t(), boolean) :: %__MODULE__{} | nil
  def get_by_username(username, case_insensitive \\ false) do
    query =
      case case_insensitive do
        false ->
          from(u in __MODULE__, where: u.username == ^username)

        true ->
          from(
            u in __MODULE__,
            where: fragment("lower(?)", ^username) == fragment("lower(?)", u.username)
          )
      end

    Repo.one(query)
  end

  @doc """
  Calculate and store cached XP values for user.

  If `update_all` is set, all of the user's cache is regenerated. Otherwise the cache is added to
  with the data after the last caching time.
  """
  @spec update_cached_xps(%__MODULE__{}, boolean) :: map
  def update_cached_xps(user, update_all \\ false) do
    update_start_time = DateTime.utc_now()

    # If update_all is given or user cache is empty, don't use any previous cache data
    empty_cache = %{
      languages: %{},
      machines: %{},
      dates: %{},
      hours: %{},
      # Time taken for the last partial cache update
      caching_duration: 0,
      # Time taken for the last full cache update
      total_caching_duration: 0
    }

    all_since = DateTime.from_naive!(~N[1970-01-01T00:00:00], "Etc/UTC")

    {xp_since, cached_data} =
      if update_all or is_nil(user.last_cached) do
        {all_since, empty_cache}
      else
        {user.last_cached, unformat_cache_from_db(user.cache)}
      end

    # Load all of user's new XP plus required associations
    xps_q =
      from(
        x in XP,
        join: p in Pulse,
        on: p.id == x.pulse_id,
        where: p.user_id == ^user.id and p.inserted_at >= ^xp_since,
        select: {p, x}
      )

    xps =
      case Repo.all(xps_q) do
        nil -> []
        ret -> ret
      end

    language_data = generate_language_cache(cached_data.languages, xps)
    machine_data = generate_machine_cache(cached_data.machines, xps)
    date_data = generate_date_cache(cached_data.dates, xps)
    hour_data = generate_hour_cache(cached_data.hours, xps)

    cache_contents = %{
      languages: language_data,
      machines: machine_data,
      dates: date_data,
      hours: hour_data
    }

    # Correct key for storing caching duration
    duration_key = if update_all, do: :total_caching_duration, else: :caching_duration

    # Store cache that is formatted for DB and add caching duration
    stored_cache =
      cache_contents
      |> format_cache_for_db()
      |> Map.put(:caching_duration, cached_data.caching_duration)
      |> Map.put(:total_caching_duration, cached_data.total_caching_duration)
      |> Map.put(duration_key, get_caching_duration(update_start_time))

    # Persist cache changes and update user's last cached timestamp
    user
    |> cast(%{cache: stored_cache}, [:cache])
    |> put_change(:last_cached, DateTime.utc_now() |> DateTime.truncate(:second))
    |> Repo.update!()

    # Return the cache data for the caller
    cache_contents
  end

  defp generate_language_cache(language_data, xps) do
    Enum.reduce(xps, language_data, fn {_, xp}, acc ->
      Map.update(acc, xp.language_id, xp.amount, &(&1 + xp.amount))
    end)
  end

  defp generate_machine_cache(machine_data, xps) do
    Enum.reduce(xps, machine_data, fn {pulse, xp}, acc ->
      Map.update(acc, pulse.machine_id, xp.amount, &(&1 + xp.amount))
    end)
  end

  defp generate_date_cache(date_data, xps) do
    Enum.reduce(xps, date_data, fn {pulse, xp}, acc ->
      date =
        case try_sent_at_local(pulse) do
          %NaiveDateTime{} = dt ->
            NaiveDateTime.to_date(dt)

          # If sent_at_local wasn't stored, use older more inaccurate data
          %DateTime{} = dt ->
            DateTime.to_date(dt)
        end

      Map.update(acc, date, xp.amount, &(&1 + xp.amount))
    end)
  end

  defp generate_hour_cache(hour_data, xps) do
    Enum.reduce(xps, hour_data, fn {pulse, xp}, acc ->
      hour = try_sent_at_local(pulse).hour
      Map.update(acc, hour, xp.amount, &(&1 + xp.amount))
    end)
  end

  # Format data in cache for storing into db as JSON
  defp format_cache_for_db(cache) do
    languages =
      Map.get(cache, :languages)
      |> int_keys_to_str()

    machines =
      Map.get(cache, :machines)
      |> int_keys_to_str()

    dates =
      Map.get(cache, :dates)
      |> Map.to_list()
      |> Enum.map(fn {key, value} -> {Date.to_iso8601(key), value} end)
      |> Map.new()

    hours =
      Map.get(cache, :hours)
      |> Map.to_list()
      |> Enum.map(fn {key, value} -> {Integer.to_string(key), value} end)
      |> Map.new()

    %{
      languages: languages,
      machines: machines,
      dates: dates,
      hours: hours
    }
  end

  # Unformat data from DB to native datatypes
  defp unformat_cache_from_db(cache) do
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

    %{
      languages: languages,
      machines: machines,
      dates: dates,
      hours: hours,
      caching_duration: Map.get(cache, "caching_duration", 0),
      total_caching_duration: Map.get(cache, "total_caching_duration", 0)
    }
  end

  defp hash_password(password) do
    Bcrypt.hashpwsalt(password)
  end

  # Common validations for creating and editing users
  defp common_validations(changeset) do
    changeset
    |> validate_format(:email, ~r/^$|@/)
  end

  # Validate that the accepted terms version is the latest one, user cannot accept older
  # terms
  defp validate_latest_terms(changeset) do
    validate_change(changeset, :terms_version, fn
      _, %Date{} = d ->
        if CodeStats.LegalTerms.is_current_version?(d) do
          []
        else
          Logger.error("Invalid legal terms version #{inspect(d)}.")
          ["Invalid legal terms version."]
        end

      _, val ->
        Logger.error("Invalid legal terms type #{inspect(val)}.")
        ["Error setting legal terms acceptance."]
    end)
  end

  defp int_keys_to_str(map) do
    map
    |> Map.to_list()
    |> Enum.map(fn {key, value} -> {Integer.to_string(key), value} end)
    |> Map.new()
  end

  defp str_keys_to_int(map) do
    map
    |> Map.to_list()
    |> Enum.map(fn {key, value} -> {Integer.parse(key) |> elem(0), value} end)
    |> Map.new()
  end

  defp get_caching_duration(start_time) do
    Calendar.DateTime.diff(DateTime.utc_now(), start_time)
    |> (fn {:ok, s, us, _} -> s + us / 1_000_000 end).()
  end

  # Try using local sent_at time if available, fall back on more inaccurate sent_at
  defp try_sent_at_local(%Pulse{} = pulse) do
    case pulse.sent_at_local do
      %NaiveDateTime{} = dt -> dt
      nil -> pulse.sent_at
    end
  end
end
