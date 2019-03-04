defmodule CodeStatsWeb.PulseController do
  use CodeStatsWeb, :controller
  require Logger

  alias Ecto.Changeset

  alias Calendar.DateTime, as: CDateTime

  alias CodeStatsWeb.AuthUtils
  alias CodeStatsWeb.ProfileChannel
  alias CodeStatsWeb.FrontpageChannel
  alias CodeStatsWeb.GeoIPPlug
  alias CodeStatsWeb.Utils.CsvFormatter

  alias CodeStats.Repo
  alias CodeStats.Language
  alias CodeStats.{User, XP}
  alias CodeStats.User.{Machine, Pulse, CacheUtils}

  @datetime_max_diff 604_800
  @rfc3339_offset_regex ~R/(\+|-)(\d{2}):?(\d{2})$/

  plug(GeoIPPlug when action in [:add])

  @spec list(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def list(conn, _params) do
    csv =
      AuthUtils.get_current_user_id(conn)
      |> XP.xps_by_user_id()
      |> Repo.all()
      |> CsvFormatter.format([
        "sent_at",
        "sent_at_local",
        "tz_offset",
        "language",
        "machine",
        "amount"
      ])

    conn
    |> put_resp_content_type("text/csv")
    |> put_resp_header("content-disposition", "attachment; filename=\"pulses.csv\"")
    |> send_resp(200, csv)
  end

  @doc """
  Action for adding a new pulse into the system.
  """
  @spec add(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def add(conn, params)

  def add(conn, %{"coded_at" => timestamp, "xps" => xps}) when is_list(xps) do
    {user, machine} = AuthUtils.get_machine_auth_details(conn)

    with {:ok, %DateTime{} = datetime} <- parse_timestamp(timestamp),
         {:ok, datetime} <- check_datetime_diff(datetime),
         {:ok, offset} <- get_offset(timestamp),
         {:ok, results} <- create_models(user, machine, datetime, offset, xps) do
      {pulse, created_xps} = Map.get(results, :pulse_add)

      # Structure xps for channel APIs
      formatted_xps =
        for %XP{language: l, amount: a} <- created_xps do
          %{language: l.name, amount: a}
        end

      # Broadcast XP data to possible viewers on profile page and frontpage
      ProfileChannel.send_pulse(user, pulse, machine, formatted_xps)

      # Coordinates are not sent for private profiles
      coords = if user.private_profile, do: nil, else: GeoIPPlug.get_coords(conn)
      FrontpageChannel.send_pulse(coords, formatted_xps)

      conn |> put_status(201) |> json(%{ok: "Great success!"})
    else
      {:error, :generic, reason} ->
        conn |> put_status(400) |> json(%{error: reason})

      {:error, failed_operation, failed_value, _} ->
        Logger.error(
          "Failure in pulse add operation: #{inspect(failed_operation)} - #{inspect(failed_value)}"
        )

        conn
        |> put_status(500)
        |> json(%{error: "Failure in operation: #{inspect(failed_operation)}"})

      {:error, err} ->
        Logger.error("Unknown pulse add error: #{inspect(err)}")

        conn
        |> put_status(500)
        |> json(%{error: "Unknown error"})
    end
  end

  # Clause for invalid params
  def add(conn, _params) do
    conn
    |> put_status(400)
    |> json(%{error: "Invalid xps format."})
  end

  # Create the database models for the pulse in a transaction, also updating the user's cache
  @spec create_models(User.t(), Machine.t(), DateTime.t(), integer, [map]) ::
          {:ok, map} | {:error, any}
  defp create_models(user, machine, datetime, offset, input_xps) do
    try do
      Ecto.Multi.new()
      |> Ecto.Multi.run(:pulse_add, fn repo, _ ->
        with {:ok, pulse} <- create_pulse(repo, user, machine, datetime, offset),
             xps <- create_xps!(repo, pulse, input_xps),
             :ok <- update_cache(repo, user, machine, datetime, offset, xps) do
          {:ok, {pulse, xps}}
        end
      end)
      |> Repo.transaction()
    rescue
      crash in RuntimeError -> {:error, :generic, crash.message}
      err -> {:error, {err, __STACKTRACE__}}
    end
  end

  # Update cache with new XP information
  @spec update_cache(Ecto.Repo.t(), User.t(), Machine.t(), DateTime.t(), integer, [XP.t()]) :: :ok
  defp update_cache(
         repo,
         %User{} = user,
         %Machine{} = machine,
         %DateTime{} = datetime,
         offset,
         xps
       )
       when is_integer(offset) and is_list(xps) do
    local_datetime = CodeStats.DateUtils.utc_and_offset_to_local(datetime, offset)

    cache =
      CacheUtils.update(
        user.cache,
        &CacheUtils.update_cache_from_xps(&1, local_datetime, machine.id, xps),
        false
      )

    cset = Changeset.cast(user, %{cache: cache}, [:cache])
    repo.update(cset)
    :ok
  end

  @spec parse_timestamp(String.t()) :: {:ok, DateTime.t()} | {:error, atom, String.t()}
  defp parse_timestamp(timestamp) do
    err_ret = {:error, :generic, "Invalid coded_at format."}

    # rfc3339_utc might crash with missing time offset, see bug: https://github.com/lau/calendar/issues/50
    try do
      case CDateTime.Parse.rfc3339_utc(timestamp) do
        {:ok, datetime} -> {:ok, datetime}
        {:bad_format, _} -> err_ret
      end
    rescue
      _ -> err_ret
    end
  end

  @spec check_datetime_diff(DateTime.t()) :: {:ok, DateTime.t()} | {:error, atom, String.t()}
  defp check_datetime_diff(datetime) do
    {:ok, diff, _, type} = CDateTime.diff(CDateTime.now_utc(), datetime)

    if type == :after and diff <= @datetime_max_diff do
      {:ok, datetime}
    else
      if type == :before or type == :same_time do
        {:ok, CDateTime.now_utc()}
      else
        {:error, :generic, "Invalid date."}
      end
    end
  end

  @spec create_pulse(Ecto.Repo.t(), User.t(), Machine.t(), DateTime.t(), integer) ::
          {:ok, Pulse.t()} | {:error, Changeset.t()}
  defp create_pulse(repo, user, machine, datetime, offset) do
    # Create shifted naive datetime from UTC datetime and offset, recreating the user's
    # local time
    local_datetime = CodeStats.DateUtils.utc_and_offset_to_local(datetime, offset)

    params = %{
      "sent_at" => datetime,
      "tz_offset" => offset,
      "sent_at_local" => local_datetime
    }

    changeset =
      Pulse.changeset(%Pulse{}, params)
      |> Changeset.put_change(:user_id, user.id)
      |> Changeset.put_change(:machine_id, machine.id)

    repo.insert(changeset)
  end

  @spec create_xps!(Ecto.Repo.t(), Pulse.t(), list) :: [XP.t()] | no_return
  defp create_xps!(repo, %Pulse{} = pulse, xps) when is_list(xps) do
    Enum.map(xps, fn
      %{"language" => language, "xp" => xp}
      when is_binary(language) and is_integer(xp) and xp >= 0 ->
        create_xp!(repo, pulse, language, xp)

      _ ->
        raise "Invalid XP format."
    end)
  end

  @spec create_xp!(Ecto.Repo.t(), Pulse.t(), String.t(), integer) :: XP.t()
  defp create_xp!(repo, %Pulse{} = pulse, language_name, xp)
       when is_binary(language_name) and is_integer(xp) and xp >= 0 do
    {:ok, language} = Language.get_or_create(repo, language_name)

    # If language was an alias of another, use that instead
    final_language =
      case language.alias_of_id do
        id when is_integer(id) -> repo.get(Language, id)
        nil -> language
      end

    xp =
      XP.changeset(%XP{}, %{"amount" => xp})
      |> Changeset.put_change(:pulse_id, pulse.id)
      |> Changeset.put_change(:language_id, final_language.id)
      |> Changeset.put_change(:original_language_id, language.id)
      |> repo.insert!()

    # Set final language into created XP so that it can be referenced later
    %{xp | language: final_language}
  end

  @spec get_offset(String.t()) :: {:ok, integer} | {:error, atom, String.t()}
  defp get_offset(timestamp) do
    # Get offset from an RFC3339 or ISO8601 string.
    timestamp = timestamp |> String.trim() |> String.downcase()

    if String.ends_with?(timestamp, "z") do
      {:ok, 0}
    else
      case Regex.run(@rfc3339_offset_regex, timestamp) do
        [_, sign, hours, minutes] -> {:ok, calculate_offset(sign, hours, minutes)}
        _ -> {:error, :generic, "Invalid TZ offset!"}
      end
    end
  end

  @spec calculate_offset(String.t(), String.t(), String.t()) :: integer
  defp calculate_offset(sign, hours, minutes)

  defp calculate_offset("+", hours, minutes), do: calculate_offset(hours, minutes)

  defp calculate_offset("-", hours, minutes), do: -calculate_offset(hours, minutes)

  @spec calculate_offset(String.t(), String.t()) :: integer
  defp calculate_offset(hours, minutes) do
    {hours, _} = Integer.parse(hours)
    {minutes, _} = Integer.parse(minutes)

    hours * 60 + minutes
  end
end
