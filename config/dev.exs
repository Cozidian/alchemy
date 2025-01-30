import Config

config :alchemy, :start_file_watcher, true
# 10 seconds
config :alchemy, :file_watcher_interval, :timer.seconds(10)
