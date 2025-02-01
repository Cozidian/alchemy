defmodule ALCHEMY.Test.TestProducer do
  use GenStage

  def start_link(_opts) do
    GenStage.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    {:producer, {:queue.new(), 0}}
  end

  def handle_info({:add_file, file_item}, {queue, pending_demand}) do
    queue = :queue.in(file_item, queue)
    dispatch_events(queue, pending_demand, [])
  end

  def handle_demand(incoming_demand, {queue, pending_demand}) do
    dispatch_events(queue, incoming_demand + pending_demand, [])
  end

  defp dispatch_events(queue, 0, events) do
    {:noreply, Enum.reverse(events), {queue, 0}}
  end

  defp dispatch_events(queue, demand, events) do
    case :queue.out(queue) do
      {{:value, event}, queue} ->
        dispatch_events(queue, demand - 1, [event | events])

      {:empty, queue} ->
        {:noreply, Enum.reverse(events), {queue, demand}}
    end
  end
end

defmodule ALCHEMY.Test.TestConsumer do
  use GenStage

  def start_link(opts) do
    GenStage.start_link(__MODULE__, opts)
  end

  def init(opts) do
    {:consumer, :ok, opts}
  end

  def handle_events(events, _from, state) do
    Enum.each(events, fn event ->
      send(Process.group_leader(), {:file_received, event})
    end)

    {:noreply, [], state}
  end
end
