defmodule DEMOALCHEMY.Supervisor do
  use Supervisor
  require Logger

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    children = [
      # Start Repo first
      DEMOALCHEMY.Repo,
      {DEMOALCHEMY.Producers.FileWatcher,
       [
         directory: Application.get_env(:demo_alchemy, :data_dir)
       ]},
      {DEMOALCHEMY.ProducerConsumers.TextProcessor,
       [
         chunk_size: 1000,
         subscribe_to: [{DEMOALCHEMY.Producers.FileWatcher, max_demand: 5}]
       ]},
      {DEMOALCHEMY.ProducerConsumers.EmbeddingProcessor,
       [
         embedding_api: Application.get_env(:demo_alchemy, :embedding_api),
         subscribe_to: [{DEMOALCHEMY.ProducerConsumers.TextProcessor, max_demand: 5}]
       ]},
      {DEMOALCHEMY.LlmQueryServer,
       [
         ollama_api: Application.get_env(:demo_alchemy, :ollama_api)
       ]},
      {DEMOALCHEMY.Consumers.VectorConsumer,
       [
         subscribe_to: [{DEMOALCHEMY.ProducerConsumers.EmbeddingProcessor, max_demand: 10}]
       ]},
      {DEMOALCHEMY.Consumers.LoggerConsumer,
       [
         chunk_size: 1000,
         subscribe_to: [{DEMOALCHEMY.ProducerConsumers.EmbeddingProcessor, max_demand: 10}]
       ]}
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end
