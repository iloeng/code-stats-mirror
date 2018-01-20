defmodule CodeStats.Profile.SchemaObjects do
  use Absinthe.Schema.Notation

  alias CodeStats.Profile.Queries

  @desc "User profile public data"
  object :profile do
    @desc "Timestamp when user registered into service"
    field(:registered, :datetime)

    @desc "Total amount of XP of user"
    field :total_xp, :integer do
      resolve(fn %{cache: cache}, _, _ ->
        {:ok, Queries.cached_total(cache)}
      end)
    end

    @desc "User's languages and their XP"
    field :languages, list_of(:profile_language) do
      arg(:since, type: :datetime)

      resolve(fn
        %{id: uid}, %{since: since}, _ ->
          {:ok, Queries.language_xps(uid, since)}

        %{cache: cache}, _, _ ->
          {:ok, Queries.cached_languages(cache)}
      end)
    end

    @desc "User's machines and their XP"
    field :machines, list_of(:profile_machine) do
      arg(:since, type: :datetime)

      resolve(fn
        %{id: uid}, %{since: since}, _ ->
          {:ok, Queries.machine_xps(uid, since)}

        %{cache: cache}, _, _ ->
          {:ok, Queries.cached_machines(cache)}
      end)
    end

    @desc "User's dates when they have been active and their XP"
    field :dates, list_of(:profile_date) do
      arg(:since, type: :datetime)

      resolve(fn
        %{cache: cache}, %{since: since}, _ ->
          {:ok, Queries.cached_dates(cache, DateTime.to_date(since))}

        %{cache: cache}, _, _ ->
          {:ok, Queries.cached_dates(cache)}
      end)
    end

    @desc "User's dates since given date with their summed XP per language per day"
    field :day_language_xps, list_of(:profile_daylanguage) do
      arg(:since, type: :date)

      resolve(fn %{id: uid}, %{since: since}, _ ->
        {:ok, Queries.day_languages(uid, since) |> IO.inspect()}
      end)
    end
  end

  @desc "Language and its total XP for a profile"
  object :profile_language do
    field(:name, :string)
    field(:xp, :integer)
  end

  @desc "Machine and its total XP for a profile"
  object :profile_machine do
    field(:name, :string)
    field(:xp, :integer)
  end

  @desc "Date when user was active and its total XP for a profile"
  object :profile_date do
    # Comes straight as ISO date format from cache
    field(:date, :string)
    field(:xp, :integer)
  end

  @desc "Date when profile has an amount of XP of the language"
  object :profile_daylanguage do
    field(:date, :date)
    field(:language, :string)
    field(:xp, :integer)
  end

  scalar :datetime, description: "RFC3339 time with timezone" do
    serialize(&Calendar.DateTime.Format.rfc3339/1)

    parse(fn %Absinthe.Blueprint.Input.String{value: dt} ->
      # rfc3339_utc might crash with missing time offset, see bug: https://github.com/lau/calendar/issues/50
      try do
        case Calendar.DateTime.Parse.rfc3339_utc(dt) do
          {:ok, val} -> {:ok, val}
          _ -> :error
        end
      rescue
        _ -> :error
      end
    end)
  end

  scalar :naive_datetime, description: "ISO 8601 naive datetime" do
    serialize(&Calendar.NaiveDateTime.Format.iso8601(&1))
  end

  scalar :date, description: "ISO 8601 date" do
    serialize(&Date.to_iso8601(&1))

    parse(fn %Absinthe.Blueprint.Input.String{value: dt} ->
      case Date.from_iso8601(dt) do
        {:ok, val} -> {:ok, val}
        _ -> :error
      end
    end)
  end
end
