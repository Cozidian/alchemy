defmodule ALCHEMY.Producers.FileWatcher do
  use GenStage
  require Logger

  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenStage.start_link(__MODULE__, opts, name: name)
  end

  def init(opts) do
    directory = Keyword.get(opts, :directory, "input/")
    interval = Keyword.get(opts, :interval, :timer.seconds(10))

    # Ensure directory exists
    File.mkdir_p!(directory)

    schedule_check(interval)

    {:producer,
     %{
       directory: directory,
       interval: interval,
       processed_files: MapSet.new(),
       demand: 0
     }}
  end

  def handle_demand(incoming_demand, %{demand: demand} = state) do
    new_state = %{state | demand: demand + incoming_demand}
    {files, state} = get_files(new_state)
    {:noreply, files, state}
  end

  def handle_info(:check_directory, state) do
    {files, new_state} = get_files(state)
    schedule_check(state.interval)

    if files == [] do
      Logger.info("No new files to process")
    end

    {:noreply, files, new_state}
  end

  defp schedule_check(interval) do
    Process.send_after(self(), :check_directory, interval)
  end

  defp get_files(%{demand: demand, processed_files: processed} = state) when demand > 0 do
    files =
      state.directory
      |> list_txt_files()
      |> Enum.reject(&MapSet.member?(processed, &1))
      |> Enum.take(demand)
      |> Enum.map(&create_file_item/1)

    new_processed = MapSet.union(processed, MapSet.new(Enum.map(files, & &1.filelocation)))
    new_state = %{state | processed_files: new_processed, demand: demand - length(files)}

    {files, new_state}
  end

  defp get_files(state), do: {[], state}

  defp list_txt_files(directory) do
    directory
    |> Path.join("*.txt")
    |> Path.wildcard()
    |> Enum.map(&Path.expand/1)
  end

  defp create_file_item(file) do
    %ALCHEMY.FileItem{
      filename: Path.basename(file),
      filelocation: file,
      timestamp: DateTime.utc_now()
    }
  end
end
