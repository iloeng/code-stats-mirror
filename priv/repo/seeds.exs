# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly
#
#     CodeStats.Repo.insert!(%CodeStats.SomeModel{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
 user = %{
   email: "test@test.test",
   username: "test",
   password: "test",
   terms_version: CodeStats.LegalTerms.get_latest_version()
 }

languages = ["elixir", "javascript"]

dates_and_xp = %{
  "date_from" => {2018,01,01}, 
  "date_to"   => {2018,02,01},
  "min" => 500,
  "max" => 1000,
  "random_time" => true
}


defmodule Seeds do

	@day_seconds 86400

	def create_date_list(%{"from" => in_from, "to" => in_to}) do
		from = Calendar.DateTime.from_erl!({in_from, {16, 00, 00}}, "Etc/UTC")
		to   = Calendar.DateTime.from_erl!({in_to, {16, 00, 00}}, "Etc/UTC")
		{:ok, diff, _, _} = Calendar.DateTime.diff(to, from)
		diff_days = div(diff, @day_seconds)

		dates = 0..diff_days
		  |> Enum.map(&advance_by_day(&1, from))
	end

	def create_date_xp_list(dates, %{"min" => min, "max" => max}) do
		random_xp = (1..Enum.count(dates))
		|> Enum.map(fn x -> Enum.random(min..max) end)
		IO.inspect Enum.count(random_xp)
		IO.inspect Enum.count(dates)
		date_xp = Enum.zip(dates, random_xp)
	end

	def create_data_for({:ok, language}, user, machine,dates_and_xp ) do
	   #{:ok, sent_at} = Calendar.DateTime.from_erl({{2018, 11, 27}, {23, 00, 00}}, "Etc/UTC")
	   #local_datetime = Calendar.DateTime.add!(sent_at, 60*60*24) |> Calendar.DateTime.to_naive()

	   dates = create_date_list(%{
		    "from" => dates_and_xp["date_from"], 
  			"to"   => dates_and_xp["date_to"] 
  	 })

		 dates_xp = create_date_xp_list(dates, %{
		 	  "min" => dates_and_xp["min"],
		    "max" => dates_and_xp["max"]
		 })

		Enum.map(dates_xp, fn {sent_at, xp} ->
			create_seed_data(sent_at, xp, user, machine, language)
		end)

	end

	def create_seed_data(sent_at, xp, user, machine, language) do
		local_datetime = Calendar.DateTime.add!(sent_at, 60*60*24) |> Calendar.DateTime.to_naive()

	    {:ok, pulse} =
	      CodeStats.User.Pulse.changeset(%CodeStats.User.Pulse{sent_at: sent_at, tz_offset: 60, sent_at_local: local_datetime}, %{})
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

	def create_user(email, username) do
	    {:ok, fetched_user} = 
	    
	    CodeStats.User.changeset(%CodeStats.User{}, 
	    	%{email: email,
		      username: username,
		      password: "test",
		      terms_version: CodeStats.LegalTerms.get_latest_version()
	    	}) 
	    |> CodeStats.Repo.insert()

	    {:ok, machine} =
	      %CodeStats.User.Machine{name: "test_machine"}
	      |> CodeStats.User.Machine.changeset(%{})
	      |> Ecto.Changeset.put_change(:user_id, fetched_user.id)
	      |> CodeStats.Repo.insert()

	    {:ok, fetched_user, machine}
	end

	defp advance_by_day(additional_day, from) do
		Calendar.DateTime.add!(from, additional_day * @day_seconds)
	end
end

{:ok, new_user, machine} = Seeds.create_user(user.email, user.username)

languages
  |> Enum.map(fn language -> language
		  |> CodeStats.Language.get_or_create
		  |> Seeds.create_data_for(new_user, machine, dates_and_xp) 
	end)
