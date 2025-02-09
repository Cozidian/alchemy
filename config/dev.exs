import Config

config :alchemy, :start_file_watcher, true
# 10 seconds
config :alchemy, :file_watcher_interval, :timer.seconds(10)
config :alchemy, :ollama_api, "http://localhost:11434/api/generate"
config :alchemy, :ollama_timeout, 30_000

config :alchemy, ALCHEMY.Repo,
  # "alchemy_dev",
  database: System.get_env("ALCHEMY_DB_NAME"),
  username: System.get_env("ALCHEMY_DB_USERNAME"),
  password: System.get_env("ALCHEMY_DB_PASSWORD"),
  hostname: System.get_env("ALCHEMY_DB_HOST"),
  port: 5432,
  types: ALCHEMY.PostgrexTypes,
  pool_size: 10
