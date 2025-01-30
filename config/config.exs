defmodule ALCHEMY.Config do
  def file_watcher_interval do
    Application.get_env(:alchemy, :file_watcher_interval, :timer.seconds(10))
  end

  def start_file_watcher? do
    Application.get_env(:alchemy, :start_file_watcher, true)
  end
end
