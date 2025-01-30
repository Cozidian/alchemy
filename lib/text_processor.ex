defmodule ALCHEMY.TextProcessor do
  use GenServer
  require Logger

  @default_interval :timer.seconds(5)
  @default_chunk_size 1000

  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    Logger.info("Starting TextProcessor with name: #{inspect(name)}")
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def init(opts) do
    interval = Keyword.get(opts, :interval, @default_interval)
    source_queue = Keyword.get(opts, :source_queue, "file_queue")
    chunk_size = Keyword.get(opts, :chunk_size, @default_chunk_size)
    queue_name = Keyword.get(opts, :queue_name, "chunk_queue")

    Logger.info("""
    Initializing TextProcessor:
      Interval: #{interval}ms
      Source Queue: #{source_queue}
      Chunk Size: #{chunk_size} characters
    """)

    ALCHEMY.Manager.create_stack(ALCHEMY.Manager, queue_name)

    schedule_check(interval)

    {:ok,
     %{
       interval: interval,
       source_queue: source_queue,
       chunk_size: chunk_size,
       queue_name: queue_name,
       processed_chunks: MapSet.new()
     }}
  end

  def handle_info(:process_next, state) do
    Logger.info("📥 TextProcessor checking queue: #{state.source_queue}")
    process_next_file(state)
    schedule_check(state.interval)
    {:noreply, state}
  end

  def get_processed_chunks do
    GenServer.call(__MODULE__, :get_processed_chunks)
  end

  def handle_call(:get_processed_chunks, _from, state) do
    {:reply, state.processed_chunks, state}
  end

  defp schedule_check(interval) do
    Process.send_after(self(), :process_next, interval)
  end

  defp process_next_file(state) do
    case ALCHEMY.Manager.pop(ALCHEMY.Manager, state.source_queue) do
      {:ok, file_item} ->
        Logger.info("Processing file: #{file_item.filename}")

        case process_file(file_item, state) do
          {:ok, chunks} ->
            Logger.info(
              "✅ Successfully processed #{file_item.filename} into #{length(chunks)} chunks"
            )

            try do
              chunk_item = %ALCHEMY.ChunkItem{
                chunk: chunks,
                meta_data: nil,
                timestamp: DateTime.utc_now()
              }

              Logger.info("Attemting to queue chunks: #{chunk_item.chunk}")

              case ALCHEMY.Manager.push(ALCHEMY.Manager, state.queue_name, chunk_item) do
                :ok ->
                  Logger.info("Successfully queued chunk: #{chunks}")

                {:error, reason} ->
                  Logger.error("Failed to queue chunks #{chunks}: #{inspect(reason)}")
              end
            rescue
              e ->
                Logger.error("Error processing chunks #{chunks}: #{inspect(e)}")
                Logger.debug(Exception.format(:error, e, __STACKTRACE__))
            end

            Logger.info("processed into chunks #{chunks}")

          {:error, reason} ->
            Logger.error("❌ Failed to process file #{file_item.filename}: #{inspect(reason)}")
        end

      {:error, :empty} ->
        Logger.debug("📭 Queue #{state.source_queue} is empty")
    end
  end

  defp process_file(file_item, state) do
    try do
      content = File.read!(file_item.filelocation)
      chunks = chunk_text(content, state.chunk_size)
      {:ok, chunks}
    rescue
      e ->
        Logger.error("Failed to process file #{file_item.filename}: #{Exception.message(e)}")
        {:error, :processing_failed}
    end
  end

  defp chunk_text(text, chunk_size) do
    text
    |> String.split(~r/\s+/)
    |> Enum.chunk_while(
      "",
      fn word, acc ->
        new_acc = if acc == "", do: word, else: acc <> " " <> word

        if String.length(new_acc) > chunk_size do
          {:cont, acc, word}
        else
          {:cont, new_acc}
        end
      end,
      fn
        "" -> {:cont, []}
        acc -> {:cont, acc, []}
      end
    )
    |> Enum.filter(&(&1 != ""))
  end
end
