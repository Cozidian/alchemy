defmodule ALCHEMYTest do
  use ExUnit.Case
  doctest ALCHEMY

  setup do
    {:ok, manager} = start_supervised(ALCHEMY.Manager)
    %{manager: manager}
  end

  # describe "stack operations" do
  #   test "create and manage a new stack", %{manager: manager} do
  #     # Create a new stack
  #     :ok = ALCHEMY.Manager.create_stack(manager, "test_stack")
  #
  #     # Stack should be empty at first
  #     assert {:error, :empty} = ALCHEMY.Manager.peek(manager, "test_stack")
  #   end
  #
  #   test "push and pop operations", %{manager: manager} do
  #     ALCHEMY.Manager.create_stack(manager, "test_stack")
  #
  #     file_item = %ALCHEMY.FileItem{
  #       filename: "test.txt",
  #       filelocation: "/test/path",
  #       timestamp: DateTime.utc_now()
  #     }
  #
  #     # Push an item
  #     :ok = ALCHEMY.Manager.push(manager, "test_stack", file_item)
  #
  #     # Peek should show the item without removing it
  #     assert {:ok, ^file_item} =
  #              manager
  #              |> ALCHEMY.Manager.peek("test_stack")
  #              |> unwrap_peek_result()
  #
  #     # Pop should remove and return the item
  #     assert {:ok, ^file_item} = ALCHEMY.Manager.pop(manager, "test_stack")
  #
  #     # Stack should be empty after pop
  #     assert {:error, :empty} = ALCHEMY.Manager.peek(manager, "test_stack")
  #   end
  #
  #   test "multiple items maintain LIFO order", %{manager: manager} do
  #     ALCHEMY.Manager.create_stack(manager, "test_stack")
  #
  #     items =
  #       for i <- 1..3 do
  #         %ALCHEMY.FileItem{
  #           filename: "file#{i}.txt",
  #           filelocation: "/path/#{i}",
  #           timestamp: DateTime.utc_now()
  #         }
  #       end
  #
  #     # Push all items
  #     Enum.each(items, fn item ->
  #       :ok = ALCHEMY.Manager.push(manager, "test_stack", item)
  #     end)
  #
  #     # Pop items and verify LIFO order
  #     for item <- Enum.reverse(items) do
  #       assert {:ok, ^item} = ALCHEMY.Manager.pop(manager, "test_stack")
  #     end
  #
  #     # Verify stack is empty
  #     assert {:error, :empty} = ALCHEMY.Manager.peek(manager, "test_stack")
  #   end
  #
  #   test "operations on non-existent stack", %{manager: manager} do
  #     assert {:error, :not_found} = ALCHEMY.Manager.peek(manager, "nonexistent")
  #     assert {:error, :not_found} = ALCHEMY.Manager.pop(manager, "nonexistent")
  #
  #     file_item = %ALCHEMY.FileItem{
  #       filename: "test.txt",
  #       filelocation: "/test",
  #       timestamp: DateTime.utc_now()
  #     }
  #
  #     assert {:error, :not_found} = ALCHEMY.Manager.push(manager, "nonexistent", file_item)
  #   end
  # end
  #
  # # Helper function to unwrap peek result
  # defp unwrap_peek_result({:ok, {:ok, item}}), do: {:ok, item}
  # defp unwrap_peek_result({:ok, {:error, :empty}}), do: {:ok, {:error, :empty}}
  # defp unwrap_peek_result(error), do: error
end
