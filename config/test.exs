import Config

config :alchemy, :start_file_watcher, false

config :alchemy, ALCHEMY.Repo,
  database: "alchemy_test",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  port: 5432,
  pool_size: 10,
  types: ALCHEMY.PostgrexTypes
