defmodule ALCHEMY.Supervisor do
  use Supervisor
  require Logger

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    interval = ALCHEMY.Config.file_watcher_interval()
    Logger.info("🔧 FileWatcher interval from config: #{interval}ms")

    children =
      [
        {DynamicSupervisor, name: ALCHEMY.QueueItemSupervisor, strategy: :one_for_one},
        {DynamicSupervisor, name: ALCHEMY.ProcessorSupervisor, strategy: :one_for_one},
        {ALCHEMY.Manager, name: ALCHEMY.Manager},
        process_children()
      ]
      |> List.flatten()

    Supervisor.init(children, strategy: :one_for_all)
  end

  defp process_children do
    if ALCHEMY.Config.start_file_watcher?() do
      queue_name = "file_queue"
      interval = ALCHEMY.Config.file_watcher_interval()

      Logger.info("Starting FileWatcher with interval: #{interval}ms")

      [
        {ALCHEMY.FileWatcher,
         [
           directory: "input/",
           interval: interval,
           queue_name: queue_name
         ]},
        {ALCHEMY.TextProcessor,
         [
           interval: :timer.seconds(5),
           source_queue: queue_name,
           chunk_size: 1000
         ]}
      ]
    else
      []
    end
  end
end
