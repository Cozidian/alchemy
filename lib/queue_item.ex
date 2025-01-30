defmodule ALCHEMY.QueueItem do
  use Agent, restart: :temporary

  @doc """
  Starts a new queue item.
  """
  def start_link(_opts) do
    Agent.start_link(fn -> [] end)
  end

  @doc """
  Pushes a new FileItem onto the stack
  """
  def push(queue_item, %ALCHEMY.FileItem{} = file_item) do
    Agent.update(queue_item, fn stack -> [file_item | stack] end)
  end

  def push(queue_item, %ALCHEMY.ChunkItem{} = chunk_item) do
    Agent.update(queue_item, fn stack -> [chunk_item | stack] end)
  end

  @doc """
  Pops an item from the stack.
  Returns `{:ok, item}` if the stack is not empty, or `{:error, :empty}` if it is.
  """
  def pop(queue_item) do
    Agent.get_and_update(queue_item, fn
      [] -> {{:error, :empty}, []}
      [head | tail] -> {{:ok, head}, tail}
    end)
  end

  @doc """
  Returns the current size of the stack
  """
  def size(queue_item) do
    Agent.get(queue_item, fn stack -> length(stack) end)
  end

  @doc """
  Peeks at the top item without removing it.
  Returns `{:ok, item}` if the stack is not empty, or `{:error, :empty}` if it is.
  """
  def peek(queue_item) do
    Agent.get(queue_item, fn
      [] -> {:error, :empty}
      [head | _] -> {:ok, head}
    end)
  end
end
