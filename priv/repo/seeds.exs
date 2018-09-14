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
#
# In the "languages" list you can append/remove names of languages to populate.
# Every language will be populated for every day with the given range
#
# In the "dates_xp" map self explainatory settings can be tweaked

# ------------

# Default user account for testing is test:test
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
# ------------

defmodule Seeds do

	@day_seconds 86400

	def create_date_list(%{"from" => in_from, "to" => in_to, "random_time" => random_time}) do

		from = Calendar.DateTime.from_erl!({in_from, {16, 00, 00}}, "Etc/UTC")
		to   = Calendar.DateTime.from_erl!({in_to, {16, 00, 00}}, "Etc/UTC")
		{:ok, diff, _, _} = Calendar.DateTime.diff(to, from)
		diff_days = div(diff, @day_seconds)

    case random_time do
      true ->	0..diff_days |> Enum.map(&advance_by_day(&1, from, true))
      
      _    -> 0..diff_days |> Enum.map(&advance_by_day(&1, from))
    end
	end

	def create_date_xp_list(dates, %{"min" => min, "max" => max}) do
		random_xp = (1..Enum.count(dates))
		|> Enum.map(fn x -> Enum.random(min..max) end)
		date_xp = Enum.zip(dates, random_xp)
	end

	def create_data_for({:ok, language}, user, machine,dates_and_xp ) do
	   dates = create_date_list(%{
		    "from" => dates_and_xp["date_from"], 
  			"to"   => dates_and_xp["date_to"],
       "random_time" => dates_and_xp["random_time"]
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

	def create_user(email, username, password) do
	    {:ok, fetched_user} = case CodeStats.User.changeset(%CodeStats.User{}, 
	    	%{email: email,
		      username: username,
		      password: password,
		      terms_version: CodeStats.LegalTerms.get_latest_version()
	    	}) 
        |> CodeStats.Repo.insert() do
        
          {:ok, fetched_user} = {:ok, fetched_user}
        end


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
  
  defp advance_by_day(additional_day, from, _) do 
    random_time = Enum.random(0..@day_seconds) 
    Calendar.DateTime.add!(from, additional_day * @day_seconds + random_time)
  end
  
end

{:ok, new_user, machine} = Seeds.create_user(user.email, user.username, user.password)

languages
  |> Enum.map(fn language -> language
		  |> CodeStats.Language.get_or_create
		  |> Seeds.create_data_for(new_user, machine, dates_and_xp) 
	end)

IO.puts("Test user account with username: #{user.username} and password #{user.password} has been created")
IO.puts("Machine with name #{machine.name} has been created")
IO.puts("Populated with languages: ")
IO.inspect(languages)
