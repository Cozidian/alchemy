defmodule ALCHEMY.TextProcessorTest do
  use ExUnit.Case
  require Logger

  setup do
    test_id = :erlang.unique_integer()
    test_queue = "test_queue_#{test_id}"
    test_name = :"text_processor_#{test_id}"

    ALCHEMY.Manager.create_stack(ALCHEMY.Manager, test_queue)

    opts = [
      interval: 100,
      source_queue: test_queue,
      chunk_size: 20,
      name: test_name
    ]

    start_supervised!({ALCHEMY.TextProcessor, opts})

    {:ok, %{test_queue: test_queue}}
  end

  test "processes text file into chunks", %{test_queue: queue} do
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

    # Push to queue and wait for processing
    :ok = ALCHEMY.Manager.push(ALCHEMY.Manager, queue, file_item)
    Process.sleep(200)

    # Clean up
    File.rm!(file)
  end

  test "handles empty files", %{test_queue: queue} do
    file = "test/temp_#{:erlang.unique_integer()}.txt"
    File.write!(file, "")

    file_item = %ALCHEMY.FileItem{
      filename: Path.basename(file),
      filelocation: file,
      timestamp: DateTime.utc_now()
    }

    :ok = ALCHEMY.Manager.push(ALCHEMY.Manager, queue, file_item)
    Process.sleep(200)

    File.rm!(file)
  end
end
