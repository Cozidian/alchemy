import Config

config :alchemy, :start_file_watcher, true
# 10 seconds
config :alchemy, :file_watcher_interval, :timer.seconds(10)
config :alchemy, :ollama_api, "http://localhost:11434/api/generate"
config :alchemy, :ollama_timeout, 30_000

config :alchemy, ALCHEMY.Repo,
  database: "alchemy_dev",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  port: 5432,
  types: ALCHEMY.PostgrexTypes,
  pool_size: 10
