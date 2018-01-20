defmodule CodeStats.Repo.Migrations.AddSentAtLocalIndex do
  use Ecto.Migration

  def change do
    # Add index for filtering by "sent_at_local" to make searches faster
    create_if_not_exists(index(:pulses, ["sent_at_local DESC"]))
  end
end
