defmodule ALCHEMY.FileWatcherTest do
  use ExUnit.Case
  require Logger

  setup do
    test_id = :erlang.unique_integer()
    test_dir = "test/input_#{test_id}"
    test_queue = "test_queue_#{test_id}"
    test_name = :"file_watcher_#{test_id}"

    # Clean up test directory
    File.rm_rf!(test_dir)
    File.mkdir_p!(test_dir)

    # Start FileWatcher with test configuration
    opts = [
      # Use test_dir instead of @test_dir
      directory: test_dir,
      interval: 100,
      # Use test_queue instead of "test_queue"
      queue_name: test_queue,
      name: test_name
    ]

    ALCHEMY.Manager.create_stack(ALCHEMY.Manager, test_queue)

    start_supervised!({ALCHEMY.FileWatcher, opts})

    on_exit(fn ->
      File.rm_rf!(test_dir)
    end)

    {:ok,
     %{
       test_dir: test_dir,
       test_queue: test_queue
     }}
  end

  test "detects and processes new txt files", %{test_dir: test_dir, test_queue: test_queue} do
    # Create a test file
    test_file = Path.join(test_dir, "test.txt")
    File.write!(test_file, "test content")

    # Wait for processing
    Process.sleep(200)

    # Check if file was queued
    assert {:ok, file_item} = ALCHEMY.Manager.peek(ALCHEMY.Manager, test_queue)
    assert file_item.filename == "test.txt"
    assert file_item.filelocation == Path.expand(test_file)
  end

  test "ignores non-txt files", %{test_dir: test_dir, test_queue: test_queue} do
    # Create non-txt file
    File.write!(Path.join(test_dir, "test.pdf"), "test content")

    # Wait for processing
    Process.sleep(200)

    # Queue should be empty
    assert {:error, :empty} = ALCHEMY.Manager.peek(ALCHEMY.Manager, test_queue)
  end

  test "handles multiple files", %{test_dir: test_dir, test_queue: test_queue} do
    # Create multiple files
    File.write!(Path.join(test_dir, "test1.txt"), "content 1")
    File.write!(Path.join(test_dir, "test2.txt"), "content 2")

    # Wait for processing
    Process.sleep(200)

    # Both files should be queued
    {:ok, item1} = ALCHEMY.Manager.pop(ALCHEMY.Manager, test_queue)
    {:ok, item2} = ALCHEMY.Manager.pop(ALCHEMY.Manager, test_queue)

    filenames = [item1.filename, item2.filename] |> Enum.sort()
    assert filenames == ["test1.txt", "test2.txt"]
  end
end
