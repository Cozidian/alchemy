defmodule ALCHEMY.Repo do
  use Ecto.Repo,
    otp_app: :alchemy,
    adapter: Ecto.Adapters.Postgres
end
