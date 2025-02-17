defmodule ALCHEMY.Producers.FileWatcherTest do
  use ExUnit.Case, async: true
  require Logger

  setup do
    test_dir = "test/temp/#{:erlang.unique_integer()}"
    File.mkdir_p!(test_dir)

    test_name = :"file_watcher_#{:erlang.unique_integer()}"

    {:ok, watcher} =
      start_supervised(
        {ALCHEMY.Producers.FileWatcher,
         [
           directory: test_dir,
           name: test_name
         ]}
      )

    {:ok, consumer} =
      start_supervised(
        {TestConsumer,
         [
           producer: watcher,
           test_pid: self()
         ]}
      )

    Process.sleep(100)

    on_exit(fn ->
      File.rm_rf!(test_dir)
    end)

    %{test_dir: test_dir, watcher: watcher, consumer: consumer}
  end

  test "detects new text files", %{test_dir: test_dir} do
    test_file = Path.join(test_dir, "test.txt")
    File.write!(test_file, "test content")

    assert_receive {:events, [file_item]}, 2000

    assert file_item.filename == "test.txt"
    assert file_item.filelocation == Path.expand(test_file)
    assert %DateTime{} = file_item.timestamp
  end

  test "ignores non-txt files", %{test_dir: test_dir} do
    File.write!(Path.join(test_dir, "test.pdf"), "test content")

    refute_receive {:events, _}, 1000
  end

  test "handles multiple files", %{test_dir: test_dir} do
    File.write!(Path.join(test_dir, "test1.txt"), "content 1")
    File.write!(Path.join(test_dir, "test2.txt"), "content 2")

    assert_receive {:events, files}, 2000

    assert length(files) == 2

    filenames = files |> Enum.map(& &1.filename) |> Enum.sort()
    assert filenames == ["test1.txt", "test2.txt"]
  end

  test "handles multiple mixed file types", %{test_dir: test_dir} do
    File.write!(Path.join(test_dir, "test1.txt"), "content 1")
    File.write!(Path.join(test_dir, "test2.txt"), "content 2")
    File.write!(Path.join(test_dir, "test3.pdf"), "content 3")

    assert_receive {:events, files}, 2000

    assert length(files) == 2

    filenames = files |> Enum.map(& &1.filename) |> Enum.sort()
    assert filenames == ["test1.txt", "test2.txt"]
  end

  test "doesn't process the same file twice", %{test_dir: test_dir} do
    test_file = Path.join(test_dir, "test.txt")

    File.write!(test_file, "initial content")
    assert_receive {:events, [_file_item]}, 2000

    File.write!(test_file, "modified content")

    refute_receive {:events, _}, 1000
  end
end
