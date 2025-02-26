defmodule ALCHEMY.Supervisor do
  use Supervisor
  require Logger

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    children = [
      # Start Repo first
      ALCHEMY.Repo,
      {ALCHEMY.Producers.FileWatcher,
       [
         directory: Application.get_env(:alchemy, :data_dir)
       ]},
      {ALCHEMY.ProducerConsumers.TextProcessor,
       [
         chunk_size: 1000,
         subscribe_to: [{ALCHEMY.Producers.FileWatcher, max_demand: 5}]
       ]},
      {ALCHEMY.ProducerConsumers.EmbeddingProcessor,
       [
         embedding_api: Application.get_env(:alchemy, :embedding_api),
         subscribe_to: [{ALCHEMY.ProducerConsumers.TextProcessor, max_demand: 5}]
       ]},
      {ALCHEMY.LlmQueryServer,
       [
         ollama_api: Application.get_env(:alchemy, :ollama_api)
       ]},
      {ALCHEMY.Consumers.VectorConsumer,
       [
         subscribe_to: [{ALCHEMY.ProducerConsumers.EmbeddingProcessor, max_demand: 10}]
       ]},
      {ALCHEMY.Consumers.LoggerConsumer,
       [
         chunk_size: 1000,
         subscribe_to: [{ALCHEMY.ProducerConsumers.EmbeddingProcessor, max_demand: 10}]
       ]}
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end
