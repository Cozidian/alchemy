import Config

config :alchemy, :start_file_watcher, false
# 10 seconds
config :alchemy, :file_watcher_interval, :timer.seconds(10)
config :alchemy, :ollama_api, "http://localhost:11434/api/generate"
config :alchemy, :embedding_api, "http://localhost:11434/api/embed"
config :alchemy, :data_dir, "input/"
config :alchemy, :ollama_timeout, 30_000

config :alchemy, ALCHEMY.Repo,
  database: System.get_env("ALCHEMY_DB_NAME"),
  username: System.get_env("ALCHEMY_DB_USERNAME"),
  password: System.get_env("ALCHEMY_DB_PASSWORD"),
  hostname: System.get_env("ALCHEMY_DB_HOST"),
  port: 5432,
  pool_size: 10,
  types: ALCHEMY.PostgrexTypes
