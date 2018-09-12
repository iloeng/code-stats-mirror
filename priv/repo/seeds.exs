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
defmodule Seeds do
	def create_data_for({:ok, language}, user, machine) do
	    {:ok, sent_at} = Calendar.DateTime.from_erl({{2018, 11, 27}, {23, 00, 00}}, "Etc/UTC")
	    local_datetime = Calendar.DateTime.add!(sent_at, 3600) |> Calendar.DateTime.to_naive()

	    {:ok, pulse} =
	      CodeStats.User.Pulse.changeset(%CodeStats.User.Pulse{sent_at: sent_at, tz_offset: 60, sent_at_local: local_datetime}, %{})
	      |> Ecto.Changeset.put_change(:user_id, user.id)
	      |> Ecto.Changeset.put_change(:machine_id, machine.id)
	      |> CodeStats.Repo.insert()

	    {:ok, _} =
	      CodeStats.XP.changeset(%CodeStats.XP{amount: 1})
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
end

{:ok, new_user, machine} = Seeds.create_user(user.email, user.username)

languages
  |> Enum.map(fn language -> language
		  |> CodeStats.Language.get_or_create
		  |> Seeds.create_data_for(new_user, machine) 
	end)
