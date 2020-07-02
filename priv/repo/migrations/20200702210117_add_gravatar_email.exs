defmodule CodeStats.Repo.Migrations.AddGravatarEmail do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:gravatar_email, :string, null: true)
    end
  end
end
