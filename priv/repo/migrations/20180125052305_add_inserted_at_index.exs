defmodule CodeStats.Repo.Migrations.AddInsertedAtIndex do
  use Ecto.Migration

  def change do
    # Add index for filtering by "inserted_at" to make caching faster
    create_if_not_exists(index(:pulses, ["inserted_at DESC"]))
  end
end
