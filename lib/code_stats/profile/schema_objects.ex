defmodule CodeStats.Profile.SchemaObjects do
  use Absinthe.Schema.Notation
  use Absinthe.Ecto, repo: CodeStats.Repo
  import Ecto.Query, only: [from: 2]

  alias CodeStats.Repo
  alias CodeStats.Profile.Queries

  @desc "User profile public data"
  object :profile do
    @desc "Timestamp when user registered into service"
    field(:registered, :datetime)

    @desc "Total amount of XP of user"
    field :total_xp, :integer do
      resolve(fn %{cache: cache}, _, _ ->
        {:ok, get_cached_total(cache)}
      end)
    end

    @desc "User's languages and their XP"
    field :languages, list_of(:profile_language) do
      arg(:since, type: :datetime)

      resolve(fn
        %{id: uid}, %{since: since}, _ ->
          {:ok, Queries.language_xps(uid, since) |> Repo.all()}

        %{cache: cache}, _, _ ->
          {:ok, get_cached_languages(cache)}
      end)
    end

    @desc "User's machines and their XP"
    field :machines, list_of(:profile_machine) do
      arg(:since, type: :datetime)

      resolve(fn
        %{id: uid}, %{since: since}, _ ->
          {:ok, Queries.machine_xps(uid, since) |> Repo.all()}

        %{cache: cache}, _, _ ->
          {:ok, get_cached_machines(cache)}
      end)
    end

    @desc "User's dates when they have been active and their XP"
    field :dates, list_of(:profile_date) do
      arg(:since, type: :datetime)

      resolve(fn
        %{cache: cache}, %{since: since}, _ ->
          {:ok, get_cached_dates(cache, since)}

        %{cache: cache}, _, _ ->
          {:ok, get_cached_dates(cache)}
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

  defp get_cached_languages(%{"languages" => languages}) when is_map(languages) do
    intkeys =
      languages
      |> Map.to_list()
      |> Enum.map(fn {k, v} -> {String.to_integer(k), v} end)
      |> Enum.into(%{})

    ids = Map.keys(intkeys)

    structs =
      from(l in CodeStats.Language, where: l.id in ^ids, select: {l.id, l.name})
      |> Repo.all()
      |> Enum.into(%{})

    Enum.map(ids, fn id -> %{name: structs[id], xp: intkeys[id]} end)
  end

  defp get_cached_total(%{"languages" => languages}) when is_map(languages) do
    languages |> Map.values() |> Enum.reduce(0, fn acc, xp -> acc + xp end)
  end

  defp get_cached_machines(%{"machines" => machines}) when is_map(machines) do
    intkeys =
      machines
      |> Map.to_list()
      |> Enum.map(fn {k, v} -> {String.to_integer(k), v} end)
      |> Enum.into(%{})

    ids = Map.keys(intkeys)

    structs =
      from(m in CodeStats.User.Machine, where: m.id in ^ids, select: {m.id, m.name})
      |> Repo.all()
      |> Enum.into(%{})

    Enum.map(ids, fn id -> %{name: structs[id], xp: intkeys[id]} end)
  end

  defp get_cached_dates(%{"dates" => dates}) when is_map(dates) do
    Map.to_list(dates)
    |> Enum.map(fn {date, xp} -> %{date: date, xp: xp} end)
  end

  defp get_cached_dates(cache, %DateTime{} = since) when is_map(cache) do
    since_date = DateTime.to_date(since)

    get_cached_dates(cache)
    |> Enum.map(fn data -> %{data | date: Date.from_iso8601!(data.date)} end)
    |> Enum.filter(fn %{date: date} -> Date.compare(date, since_date) != :lt end)
  end
end
