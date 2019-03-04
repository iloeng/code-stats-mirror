defmodule CodeStats.Repo.Migrations.NotNulls do
  use Ecto.Migration

  def change do
    alter table(:xps) do
      modify(:amount, :integer, null: false)
      modify(:pulse_id, :bigint, null: false)
      modify(:language_id, :integer, null: false)
      modify(:original_language_id, :integer, null: false)
    end

    alter table(:pulses) do
      modify(:sent_at, :timestamp, null: false)
      modify(:user_id, :integer, null: false)
      modify(:machine_id, :integer, null: false)
    end

    alter table(:password_resets) do
      modify(:token, :uuid, null: false)
      modify(:user_id, :integer, null: false)
    end

    alter table(:machines) do
      modify(:name, :string, null: false)
      modify(:user_id, :integer, null: false)
      modify(:api_salt, :string, null: false)
    end

    alter table(:languages) do
      modify(:name, :string, null: false)
    end
  end
end
