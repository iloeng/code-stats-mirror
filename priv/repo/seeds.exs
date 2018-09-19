# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# If you wish to setup the database from scratch including everything, you can use
#
#     mix ecto.setup
#
# This script creates a given user from the "user" map. 
# You can change credentials as you wish below.
# Or supply environment variables:
#
#     SEED_USER,      format user:password
#     SEED_EMAIL,     format email@email.email
#     SEED_MACHINE,   format machine_name
#
#     SEED_DATE_FROM, format YYYY,MM,DD
#     SEED_DATE_TO,   format YYYY,MM,DD
#
#     SEED_MIN,       format number
#     SEED_MAX,       format number
#
#     SEED_LANG,      format Language1,Language2,Language3,...
#     SEED_RANDOM,    format true/false
#
#     SEED_RANDOM decides whether or not to spread out experience randomly throughout the day(s)
#
#     Example run of the seed script:
"""
     SEED_USER=test2:test2 SEED_EMAIL=test2@test2.test \
     SEED_MACHINE=machine2 SEED_DATE_FROM=2018,07,01 \
     SEED_DATE_TO=2018,08,01 SEED_MIN=1000 SEED_MAX=2000 \
     SEED_LANG=Java,Scala SEED_RANDOM=false mix run priv/repo/seeds.exs
"""

#    The above data uses values different from default.
#
# If any of the environment variables are not supplied before the script is called
# the script will take on the below default values. This lets you seed data to the same
# account for different languages, date ranges and xp ranges if you wish.
#
# This script can be run multiple times without overwriting existing date, just adding new.
# This means seeded data for multiple machines and multiple languages is easily done.
# Resetting the database can be done with
# 
#     mix ecto.reset
#
# In the "languages" list you can append/remove names of languages to populate.
# Every language will be populated for every day with the given range.
#
# In the "dates_xp" map self explainatory settings can be tweaked.

# Default values. Change as env_vars or from here
# ------------
default_user = "test:test"
default_email = "test@test.test"

default_machine = "test_machine"

default_languages = ["Elixir", "JavaScript"]

date_from_month = if DateTime.utc_now().month - 1 == 0, do: 1, else: DateTime.utc_now().month - 1
date_to_month = if DateTime.utc_now().month == 1, do: 2, else: DateTime.utc_now().month

default_dates_and_xp = %{
  date_from: {DateTime.utc_now().year, date_from_month, 01},
  date_to: {DateTime.utc_now().year, date_to_month, 01},
  min: 500,
  max: 700,
  random_time: true
}

# --------------

defmodule Seeds do
  @day_seconds 86400

  def get_or_create_user(email, username, password, machine_name) do
    {:ok, fetched_user, machine} =
      case CodeStats.User.get_by_username(username, true) do
        nil ->
          create_new_user(
            %{
              email: email,
              username: username,
              password: password,
              terms_version: CodeStats.LegalTerms.get_latest_version()
            },
            machine_name
          )

        user ->
          machine = get_or_create_machine(user, machine_name)

          {:ok, user, machine}
      end

    {:ok, fetched_user, machine}
  end

  defp create_new_user(user_map, machine_name) do
    {:ok, fetched_user} =
      CodeStats.User.changeset(%CodeStats.User{}, user_map)
      |> CodeStats.Repo.insert()

    {:ok, machine} =
      %CodeStats.User.Machine{name: machine_name}
      |> CodeStats.User.Machine.changeset(%{})
      |> Ecto.Changeset.put_change(:user_id, fetched_user.id)
      |> CodeStats.Repo.insert()

    {:ok, fetched_user, machine}
  end

  defp get_or_create_machine(user, machine_name) do
    case CodeStats.Repo.get_by(CodeStats.User.Machine, user_id: user.id, name: machine_name) do
      nil ->
        {:ok, machine} =
          %CodeStats.User.Machine{name: machine_name}
          |> CodeStats.User.Machine.changeset(%{})
          |> Ecto.Changeset.put_change(:user_id, user.id)
          |> CodeStats.Repo.insert()

        machine

      machine ->
        machine
    end
  end

  def create_data_for({:ok, language}, user, machine, dates_and_xp) do
    dates =
      create_date_list(%{
        from: dates_and_xp.date_from,
        to: dates_and_xp.date_to,
        random_time: dates_and_xp.random_time
      })

    dates_xp =
      create_date_xp_list(dates, %{
        min: dates_and_xp.min,
        max: dates_and_xp.max
      })

    Enum.map(dates_xp, fn {sent_at, xp} ->
      create_pulse_and_xp(sent_at, xp, user, machine, language)
    end)
  end

  defp create_date_list(%{from: in_from, to: in_to, random_time: random_time}) do
    from = Calendar.DateTime.from_erl!({in_from, {16, 00, 00}}, "Etc/UTC")
    to = Calendar.DateTime.from_erl!({in_to, {16, 00, 00}}, "Etc/UTC")
    {:ok, diff, _, _} = Calendar.DateTime.diff(to, from)

    diff_days = div(diff, @day_seconds)

    case random_time do
      true -> 0..diff_days |> Enum.map(&advance_by_day(&1, from, true))
      _ -> 0..diff_days |> Enum.map(&advance_by_day(&1, from))
    end
  end

  defp create_date_xp_list(dates, %{min: min, max: max}) do
    random_xp =
      1..Enum.count(dates)
      |> Enum.map(fn x -> Enum.random(min..max) end)

    date_xp = Enum.zip(dates, random_xp)
  end

  def create_pulse_and_xp(sent_at, xp, user, machine, language) do
    local_datetime = sent_at |> Calendar.DateTime.to_naive()

    {:ok, pulse} =
      CodeStats.User.Pulse.changeset(
        %CodeStats.User.Pulse{sent_at: sent_at, tz_offset: 60, sent_at_local: local_datetime},
        %{}
      )
      |> Ecto.Changeset.put_change(:user_id, user.id)
      |> Ecto.Changeset.put_change(:machine_id, machine.id)
      |> CodeStats.Repo.insert()

    {:ok, _} =
      CodeStats.XP.changeset(%CodeStats.XP{amount: xp})
      |> Ecto.Changeset.put_change(:pulse_id, pulse.id)
      |> Ecto.Changeset.put_change(:language_id, language.id)
      |> Ecto.Changeset.put_change(:original_language_id, language.id)
      |> CodeStats.Repo.insert()
  end

  defp advance_by_day(additional_day, from),
    do: Calendar.DateTime.add!(from, additional_day * @day_seconds)

  defp advance_by_day(additional_day, from, _) do
    random_time = Enum.random(0..@day_seconds)
    Calendar.DateTime.add!(from, additional_day * @day_seconds + random_time)
  end

  def env_get_user(env_var), do: String.trim(env_var) |> String.split(":") |> List.to_tuple()

  def env_get_lang(env_var) when is_binary(env_var),
    do: String.trim(env_var) |> String.split(",") |> Enum.filter(&string_not_empty?(&1))

  def env_get_lang(env_var), do: Enum.filter(env_var, &string_not_empty?(&1))

  defp string_not_empty?(string) when is_binary(string), do: string != ""

  def env_get_date(env_var, default_var) do
    # Date should be in format yyyy,mm,dd
    case System.get_env(env_var) do
      nil ->
        default_var

      x ->
        x
        |> String.trim()
        |> String.split(",")
        |> Enum.filter(&string_not_empty?/1)
        |> Enum.map(&String.to_integer/1)
        |> List.to_tuple()
    end
  end

  def env_to_bool(env_var, default_var) do
    case System.get_env(env_var) do
      nil ->
        default_var

      x ->
        x
        |> String.trim()
        |> String.to_existing_atom()
    end
  end

  def env_xp(env_var, default_var) do
    case System.get_env(env_var) do
      nil -> default_var
      x -> String.to_integer(x)
    end
  end
end

{env_username, env_password} = Seeds.env_get_user(System.get_env("SEED_USER") || default_user)
env_email = System.get_env("SEED_EMAIL") || default_email

env_machine = System.get_env("SEED_MACHINE") || default_machine

env_languages = Seeds.env_get_lang(System.get_env("SEED_LANG") || default_languages)

initial_user = %{
  email: env_email,
  username: env_username,
  password: env_password,
  terms_version: CodeStats.LegalTerms.get_latest_version()
}

dates_and_xp = %{
  date_from: Seeds.env_get_date("SEED_DATE_FROM", default_dates_and_xp.date_from),
  date_to: Seeds.env_get_date("SEED_DATE_TO", default_dates_and_xp.date_to),
  min: Seeds.env_xp("SEED_MIN", default_dates_and_xp.min),
  max: Seeds.env_xp("SEED_MAX", default_dates_and_xp.max),
  random_time: Seeds.env_to_bool("SEED_RANDOM", default_dates_and_xp.random_time)
}

{:ok, user, machine} =
  Seeds.get_or_create_user(
    initial_user.email,
    initial_user.username,
    initial_user.password,
    env_machine
  )

env_languages
|> Enum.map(fn language ->
  language
  |> CodeStats.Language.get_or_create()
  |> Seeds.create_data_for(user, machine, dates_and_xp)
end)

IO.puts(
  "Test user account with username: #{initial_user.username}, password #{initial_user.password} has been created"
)

IO.puts("Machine with name #{env_machine} has been created/updated")
IO.puts("Populated with languages: ")
IO.inspect(env_languages)
IO.puts("With experience ranging from #{dates_and_xp.min} to #{dates_and_xp.max}")
