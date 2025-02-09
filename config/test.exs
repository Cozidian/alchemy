import Config

config :alchemy, :start_file_watcher, false

config :alchemy, ALCHEMY.Repo,
  database: System.get_env("ALCHEMY_DB_NAME"),
  username: System.get_env("ALCHEMY_DB_USERNAME"),
  password: System.get_env("ALCHEMY_DB_PASSWORD"),
  hostname: System.get_env("ALCHEMY_DB_HOST"),
  port: 5432,
  pool_size: 10,
  types: ALCHEMY.PostgrexTypes
