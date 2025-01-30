defmodule ALCHEMY.Manager do
  use GenServer

  @doc """
  Starts the manager.
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @doc """
  Create a stack
  """
  def create_stack(server, name) do
    GenServer.cast(server, {:create, name})
  end

  def push(server, name, file_item) do
    GenServer.call(server, {:push, name, file_item})
  end

  def pop(server, name) do
    GenServer.call(server, {:pop, name})
  end

  def peek(server, name) do
    GenServer.call(server, {:peek, name})
  end

  @impl true
  def init(:ok) do
    names = %{}
    refs = %{}
    {:ok, {names, refs}}
  end

  @impl true
  def handle_call({:peek, name}, _from, state) do
    {names, _} = state

    case Map.fetch(names, name) do
      {:ok, pid} ->
        {:reply, ALCHEMY.QueueItem.peek(pid), state}

      :error ->
        {:reply, {:error, :not_found}, state}
    end
  end

  @impl true
  def handle_call({:pop, name}, _from, state) do
    {names, _} = state

    case Map.fetch(names, name) do
      {:ok, pid} ->
        result = ALCHEMY.QueueItem.pop(pid)
        {:reply, result, state}

      :error ->
        {:reply, {:error, :not_found}, state}
    end
  end

  @impl true
  def handle_call({:push, name, file_item}, _from, state) do
    {names, _} = state

    case Map.fetch(names, name) do
      {:ok, pid} ->
        result = ALCHEMY.QueueItem.push(pid, file_item)
        {:reply, result, state}

      :error ->
        {:reply, {:error, :not_found}, state}
    end
  end

  @impl true
  def handle_cast({:create, name}, {names, refs}) do
    if Map.has_key?(names, name) do
      {:noreply, {names, refs}}
    else
      {:ok, pid} = DynamicSupervisor.start_child(ALCHEMY.QueueItemSupervisor, ALCHEMY.QueueItem)
      ref = Process.monitor(pid)
      refs = Map.put(refs, ref, name)
      names = Map.put(names, name, pid)
      {:noreply, {names, refs}}
    end
  end

  @impl true
  def handle_info({:DOWN, ref, :process, _pid, _reason}, {names, refs}) do
    {name, refs} = Map.pop(refs, ref)
    names = Map.delete(names, name)
    {:noreply, {names, refs}}
  end
end
