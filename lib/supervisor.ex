defmodule ALCHEMY.Supervisor do
  use Supervisor
  require Logger

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    interval = ALCHEMY.Config.file_watcher_interval()

    children = [
      {ALCHEMY.Producers.FileWatcher,
       [
         directory: "input/",
         interval: interval
       ]},
      {ALCHEMY.ProducerConsumers.TextProcessor,
       [
         chunk_size: 1000,
         subscribe_to: [{ALCHEMY.Producers.FileWatcher, max_demand: 5}]
       ]},
      {ALCHEMY.Consumers.LoggerConsumer,
       [
         chunk_size: 1000,
         subscribe_to: [{ALCHEMY.ProducerConsumers.TextProcessor, max_demand: 10}]
       ]}
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end
