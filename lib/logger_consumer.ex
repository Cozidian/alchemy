defmodule ALCHEMY.Consumers.LoggerConsumer do
  use GenStage
  require Logger

  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenStage.start_link(__MODULE__, opts, name: name)
  end

  def init(opts) do
    subscribe_to = Keyword.get(opts, :subscribe_to, [ALCHEMY.ProducerConsumers.TextProcessor])

    {:consumer, :ok, subscribe_to: subscribe_to}
  end

  def handle_events(chunks, _from, state) do
    for chunk <- chunks do
      Logger.info("Received chunk: #{inspect(chunk)}")
    end

    {:noreply, [], state}
  end
end
