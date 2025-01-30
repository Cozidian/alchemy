defmodule ALCHEMY.FileWatcher do
  use GenServer
  require Logger

  @default_interval :timer.minutes(5)

  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def init(opts) do
    directory = Keyword.get(opts, :directory, "input/")
    interval = Keyword.get(opts, :interval, @default_interval)
    queue_name = Keyword.get(opts, :queue_name, "file_queue")

    # Ensure directory exists
    File.mkdir_p!(directory)

    ALCHEMY.Manager.create_stack(ALCHEMY.Manager, queue_name)

    # Schedule first check
    schedule_check(interval)

    {:ok,
     %{
       directory: directory,
       interval: interval,
       queue_name: queue_name,
       processed_files: MapSet.new()
     }}
  end

  def handle_info(:check_directory, state) do
    Logger.info("File watcher check directory: #{state.directory}")
    new_state = process_directory(state)
    Logger.debug("Scheduling next check in: #{state.interval}ms")
    schedule_check(state.interval)
    {:noreply, new_state}
  end

  defp schedule_check(interval) do
    Process.send_after(self(), :check_directory, interval)
  end

  defp process_directory(state) do
    files = list_txt_files(state.directory)

    new_files =
      files
      |> Enum.reject(fn file ->
        MapSet.member?(state.processed_files, file)
      end)

    process_new_files(new_files, state)

    # Update processed files list
    %{state | processed_files: MapSet.new(files)}
  end

  defp list_txt_files(directory) do
    Logger.debug("Scanning directory: #{directory}")

    files =
      directory
      |> Path.join("*.txt")
      |> Path.wildcard()
      |> Enum.map(&Path.expand/1)

    Logger.debug("Found files: #{inspect(files)}")
    files
  end

  defp process_new_files(files, state) do
    Enum.each(files, fn file ->
      try do
        file_item = %ALCHEMY.FileItem{
          filename: Path.basename(file),
          filelocation: file,
          timestamp: DateTime.utc_now()
        }

        Logger.info("Attemting to queue file: #{file_item.filename}")
        case ALCHEMY.Manager.push(ALCHEMY.Manager, state.queue_name, file_item) do
          :ok ->
            Logger.info("Successfully queued file: #{file}")

          {:error, reason} ->
            Logger.error("Failed to queue file #{file}: #{inspect(reason)}")
        end
      rescue
        e ->
          Logger.error("Error processing file #{file}: #{inspect(e)}")
          Logger.debug(Exception.format(:error, e, __STACKTRACE__))
      end
    end)
  end

  # API functions
  def get_processed_files do
    GenServer.call(__MODULE__, :get_processed_files)
  end

  def handle_call(:get_processed_files, _from, state) do
    {:reply, state.processed_files, state}
  end
end
