import Config

config :demo_alchemy, :start_file_watcher, true
# 10 seconds
config :demo_alchemy, :file_watcher_interval, :timer.seconds(10)
config :demo_alchemy, :ollama_api, "http://localhost:11434/api/generate"
config :demo_alchemy, :embedding_api, "http://localhost:11434/api/embed"
config :demo_alchemy, :data_dir, "input/"
config :demo_alchemy, :ollama_timeout, 30_000

config :demo_alchemy, DEMOALCHEMY.Repo,
  # "demo_alchemy_dev",
  database: System.get_env("DEMOALCHEMY_DB_NAME"),
  username: System.get_env("DEMOALCHEMY_DB_USERNAME"),
  password: System.get_env("DEMOALCHEMY_DB_PASSWORD"),
  hostname: System.get_env("DEMOALCHEMY_DB_HOST"),
  port: 5432,
  types: DEMOALCHEMY.PostgrexTypes,
  pool_size: 10
