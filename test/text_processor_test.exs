defmodule ALCHEMY.ProducerConsumers.TextProcessorTest do
  use ExUnit.Case, async: true
  require Logger
  alias ALCHEMY.Test.{TestProducer, TestConsumer}

  setup do
    test_name = :"text_processor_#{:erlang.unique_integer()}"

    # Start a test producer
    {:ok, producer} = start_supervised({TestProducer, []})

    # Start the TextProcessor
    {:ok, processor} =
      start_supervised({
        ALCHEMY.ProducerConsumers.TextProcessor,
        [
          name: test_name,
          chunk_size: 20,
          subscribe_to: [{producer, max_demand: 5}]
        ]
      })

    # Start a test consumer
    test_consumer = start_supervised!({TestConsumer, subscribe_to: [{processor, max_demand: 10}]})

    %{
      producer: producer,
      processor: processor,
      consumer: test_consumer
    }
  end

  test "processes text file into chunks", %{producer: producer} do
    # Create a test file item
    content =
      "This is a test file with multiple words that should be split into chunks based on size"

    file = "test/temp_#{:erlang.unique_integer()}.txt"
    File.write!(file, content)

    file_item = %ALCHEMY.FileItem{
      filename: Path.basename(file),
      filelocation: file,
      timestamp: DateTime.utc_now()
    }

    # Send the file item to the processor
    send(producer, {:add_file, file_item})

    # Verify chunks are received
    assert_receive {:chunk_received, chunk_item}, 1000
    assert is_binary(chunk_item.chunk)

    # Clean up
    File.rm!(file)
  end

  test "handles empty files", %{producer: producer} do
    file = "test/temp_#{:erlang.unique_integer()}.txt"
    File.write!(file, "")

    file_item = %ALCHEMY.FileItem{
      filename: Path.basename(file),
      filelocation: file,
      timestamp: DateTime.utc_now()
    }

    send(producer, {:add_file, file_item})

    refute_receive {:chunk_received, _}, 500

    File.rm!(file)
  end
end

# Test Producer for TextProcessor
defmodule TestProducer do
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

# Test Consumer for TextProcessor
defmodule TestConsumer do
  use GenStage

  def start_link(opts) do
    GenStage.start_link(__MODULE__, opts)
  end

  def init(opts) do
    {:consumer, :ok, opts}
  end

  def handle_events(events, _from, state) do
    Enum.each(events, fn event ->
      send(Process.group_leader(), {:chunk_received, event})
    end)

    {:noreply, [], state}
  end
end
