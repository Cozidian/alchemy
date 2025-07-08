Postgrex.Types.define(
  DEMOALCHEMY.PostgrexTypes,
  Pgvector.extensions() ++ Ecto.Adapters.Postgres.extensions(),
  []
)
