defmodule ALCHEMY.QueueItemTest do
  use ExUnit.Case, async: true

  setup do
    {:ok, queue} = ALCHEMY.QueueItem.start_link([])
    %{queue: queue}
  end

  describe "queue item operations" do
    test "new queue is empty", %{queue: queue} do
      assert {:error, :empty} = ALCHEMY.QueueItem.peek(queue)
      assert 0 = ALCHEMY.QueueItem.size(queue)
    end

    test "push and pop single item", %{queue: queue} do
      file_item = %ALCHEMY.FileItem{
        filename: "test.txt",
        filelocation: "/test",
        timestamp: DateTime.utc_now()
      }

      :ok = ALCHEMY.QueueItem.push(queue, file_item)
      assert 1 = ALCHEMY.QueueItem.size(queue)
      assert {:ok, ^file_item} = ALCHEMY.QueueItem.peek(queue)
      assert {:ok, ^file_item} = ALCHEMY.QueueItem.pop(queue)
      assert 0 = ALCHEMY.QueueItem.size(queue)
    end

    test "maintains LIFO order with multiple items", %{queue: queue} do
      items =
        for i <- 1..3 do
          %ALCHEMY.FileItem{
            filename: "file#{i}.txt",
            filelocation: "/path/#{i}",
            timestamp: DateTime.utc_now()
          }
        end

      Enum.each(items, &ALCHEMY.QueueItem.push(queue, &1))
      assert 3 = ALCHEMY.QueueItem.size(queue)

      # Items should come out in reverse order (LIFO)
      for item <- Enum.reverse(items) do
        assert {:ok, ^item} = ALCHEMY.QueueItem.pop(queue)
      end

      assert 0 = ALCHEMY.QueueItem.size(queue)
    end
  end
end
