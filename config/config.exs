import Config
config :demo_alchemy, ecto_repos: [DEMOALCHEMY.Repo]

defmodule DEMOALCHEMY.Config do
  def file_watcher_interval do
    Application.get_env(:demo_alchemy, :file_watcher_interval, :timer.seconds(10))
  end

  def start_file_watcher? do
    Application.get_env(:demo_alchemy, :start_file_watcher, true)
  end
end

import_config "#{config_env()}.exs"
