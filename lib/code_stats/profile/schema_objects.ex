defmodule CodeStats.Profile.SchemaObjects do
  use Absinthe.Schema.Notation
  use Absinthe.Ecto, repo: CodeStats.Repo

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

  scalar :datetime, description: "RFC3339 time with timezone" do
    serialize(&Calendar.DateTime.Format.rfc3339/1)

    parse(fn %Absinthe.Blueprint.Input.String{value: dt} ->
      Calendar.DateTime.Parse.rfc3339_utc(dt)
    end)
  end

  scalar :naive_datetime, description: "ISO 8601 naive datetime" do
    serialize(&Calendar.NaiveDateTime.Format.iso8601(&1))
  end
end
