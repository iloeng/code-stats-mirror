defmodule CodeStats.Repo.Migrations.AddTermsAcceptanceDate do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:terms_version, :date, null: false, default: "2016-08-02")
    end
  end
end
