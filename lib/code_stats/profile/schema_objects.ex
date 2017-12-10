defmodule CodeStats.Profile.SchemaObjects do
  use Absinthe.Schema.Notation
  use Absinthe.Ecto, repo: CodeStats.Repo
  import Ecto.Query, only: [from: 2]

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

    @desc "Get all of users languages and their total XP"
    field :languages, list_of(:profile_language) do
      arg(:since, type: :datetime)

      resolve(fn _, %{since: since}, _ ->
        IO.inspect(since)
        {:ok, []}
      end)
    end
  end

  object :pulse do
    field(:sent_at, :datetime)
    field(:sent_at_local, :naive_datetime)
    field(:tz_offset, :integer)
  end

  object :profile_language do
    field(:name, :string)
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
      |> CodeStats.Repo.all()
      |> Enum.into(%{})

    Enum.map(ids, fn id -> %{name: structs[id], xp: intkeys[id]} end)
  end

  defp get_cached_total(%{"languages" => languages}) when is_map(languages) do
    languages |> Map.values() |> Enum.reduce(0, fn acc, xp -> acc + xp end)
  end
end
