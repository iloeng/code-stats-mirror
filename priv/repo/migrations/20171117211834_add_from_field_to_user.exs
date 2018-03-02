defmodule CodeStats.Repo.Migrations.AddFromFieldToUser do
  use Ecto.Migration

  def up do
    alter table(:users) do
      add :from, :text, null: true
    end

    execute "update users set \"from\" = 'codestats'"

    alter table(:users) do
      modify :from, :text, null: false
    end
  end

  def down do
    alter table(:users) do
      remove :from
    end
  end
end
