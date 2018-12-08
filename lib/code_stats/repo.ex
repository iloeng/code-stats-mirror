defmodule CodeStats.Repo do
  use Ecto.Repo, otp_app: :code_stats, adapter: Ecto.Adapters.Postgres
end
