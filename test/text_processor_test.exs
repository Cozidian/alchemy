defmodule ALCHEMY.ProducerConsumers.TextProcessorTest do
  use ExUnit.Case, async: true
  require Logger

  setup do
    test_name = :"text_processor_#{:erlang.unique_integer()}"

    {:ok, producer} = start_supervised({TestProducer, []})

    {:ok, processor} =
      start_supervised({
        ALCHEMY.ProducerConsumers.TextProcessor,
        [
          name: test_name,
          chunk_size: 20,
          subscribe_to: [{producer, max_demand: 5}]
        ]
      })

    {:ok, consumer} =
      start_supervised(
        {TestConsumer,
         [
           producer: processor,
           test_pid: self()
         ]}
      )

    %{
      producer: producer,
      processor: processor,
      consumer: consumer
    }
  end

  test "processes text file into chunks", %{producer: producer} do
    content = String.duplicate("word ", 10)
    file = "test/temp_#{:erlang.unique_integer()}.txt"
    File.write!(file, content)

    file_item = %ALCHEMY.FileItem{
      filename: Path.basename(file),
      filelocation: file,
      timestamp: DateTime.utc_now()
    }

    send(producer, {:add_file, file_item})

    assert_receive {:events, chunks}, 1000

    Enum.each(chunks, fn chunk ->
      assert %ALCHEMY.ChunkItem{} = chunk
      assert is_binary(chunk.chunk)
      assert String.length(chunk.chunk) <= 20
      assert chunk.timestamp != nil
    end)

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

    refute_receive {:events, _}, 500

    File.rm!(file)
  end

  test "handles non-existent files", %{producer: producer} do
    file_item = %ALCHEMY.FileItem{
      filename: "non_existent.txt",
      filelocation: "non_existent.txt",
      timestamp: DateTime.utc_now()
    }

    send(producer, {:add_file, file_item})

    refute_receive {:events, _}, 500
  end

  test "processes multiple chunks correctly", %{producer: producer} do
    content = String.duplicate("This is a longer sentence that will need chunking. ", 5)
    file = "test/temp_#{:erlang.unique_integer()}.txt"
    File.write!(file, content)

    file_item = %ALCHEMY.FileItem{
      filename: Path.basename(file),
      filelocation: file,
      timestamp: DateTime.utc_now()
    }

    send(producer, {:add_file, file_item})

    assert_receive {:events, chunks}, 1000

    assert length(chunks) > 1

    Enum.each(chunks, fn chunk ->
      assert String.length(chunk.chunk) <= 20
    end)

    all_content = chunks |> Enum.map(& &1.chunk) |> Enum.join(" ")
    assert String.length(all_content) > 0

    File.rm!(file)
  end
end
