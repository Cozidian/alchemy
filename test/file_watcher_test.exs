defmodule ALCHEMY.Producers.FileWatcherTest do
  use ExUnit.Case, async: true
  require Logger
  alias ALCHEMY.Test.TestConsumer

  setup do
    # Create a temporary directory for test files
    test_dir = "test/temp/#{:erlang.unique_integer()}"
    File.mkdir_p!(test_dir)

    # Start the FileWatcher with our test directory
    test_name = :"file_watcher_#{:erlang.unique_integer()}"

    opts = [
      name: test_name,
      directory: test_dir,
      interval: 100
    ]

    {:ok, watcher} = start_supervised({ALCHEMY.Producers.FileWatcher, opts})

    # Create a test consumer to receive files
    test_consumer = start_supervised!({TestConsumer, subscribe_to: [{watcher, max_demand: 1}]})

    on_exit(fn ->
      File.rm_rf!(test_dir)
    end)

    %{
      test_dir: test_dir,
      watcher: watcher,
      consumer: test_consumer
    }
  end

  test "detects new text files", %{test_dir: test_dir, consumer: consumer} do
    # Create a test file
    test_file = Path.join(test_dir, "test.txt")
    File.write!(test_file, "test content")

    # Wait for processing
    assert_receive {:file_received, file_item}, 1000
    assert file_item.filename == "test.txt"
    assert file_item.filelocation == Path.expand(test_file)
  end

  test "ignores non-txt files", %{test_dir: test_dir} do
    # Create non-txt file
    File.write!(Path.join(test_dir, "test.pdf"), "test content")

    # Should not receive any files
    refute_receive {:file_received, _}, 500
  end

  test "handles multiple files", %{test_dir: test_dir} do
    # Create multiple files
    File.write!(Path.join(test_dir, "test1.txt"), "content 1")
    File.write!(Path.join(test_dir, "test2.txt"), "content 2")

    # Collect received files
    assert_receive {:file_received, file1}, 1000
    assert_receive {:file_received, file2}, 1000

    filenames = [file1.filename, file2.filename] |> Enum.sort()
    assert filenames == ["test1.txt", "test2.txt"]
  end
end

# Test Consumer for FileWatcher
defmodule TestConsumer do
  use GenStage

  def start_link(opts) do
    GenStage.start_link(__MODULE__, opts)
  end

  def init(opts) do
    {:consumer, :ok, opts}
  end

  def handle_events(events, _from, state) do
    # Send received files to test process
    Enum.each(events, fn event ->
      send(Process.group_leader(), {:file_received, event})
    end)

    {:noreply, [], state}
  end
end
