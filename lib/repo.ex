defmodule DEMOALCHEMY.Repo do
  use Ecto.Repo,
    otp_app: :demo_alchemy,
    adapter: Ecto.Adapters.Postgres
end
