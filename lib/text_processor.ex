defmodule ALCHEMY.ProducerConsumers.TextProcessor do
  use GenStage
  require Logger

  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenStage.start_link(__MODULE__, opts, name: name)
  end

  def init(opts) do
    chunk_size = Keyword.get(opts, :chunk_size, 1000)

    subscribe_to = Keyword.get(opts, :subscribe_to, [ALCHEMY.Producers.FileWatcher])

    {:producer_consumer, %{chunk_size: chunk_size}, subscribe_to: subscribe_to}
  end

  def handle_events(files, _from, state) do
    chunks =
      files
      |> Enum.flat_map(&process_file(&1, state.chunk_size))
      |> Enum.map(&create_chunk_item/1)

    # Logger.info("filename: #{files.name} is chunked into: #{length(chunks)}")
    {:noreply, chunks, state}
  end

  defp process_file(file_item, chunk_size) do
    try do
      file_item.filelocation
      |> File.read!()
      |> chunk_text(chunk_size)
    rescue
      e ->
        Logger.error("Failed to process file #{file_item.filename}: #{Exception.message(e)}")
        []
    end
  end

  defp chunk_text(text, chunk_size) do
    text
    |> String.split(~r/\s+/)
    |> Enum.chunk_while(
      [],
      fn word, acc ->
        new_acc = acc ++ [word]
        chunk = Enum.join(new_acc, " ")

        if String.length(chunk) > chunk_size do
          {:cont, Enum.join(acc, " "), [word]}
        else
          {:cont, new_acc}
        end
      end,
      fn
        [] -> {:cont, []}
        acc -> {:cont, Enum.join(acc, " "), []}
      end
    )
    |> Enum.filter(&(&1 != ""))
  end

  defp create_chunk_item(chunk) do
    %ALCHEMY.ChunkItem{
      chunk: chunk,
      meta_data: nil,
      timestamp: DateTime.utc_now()
    }
  end
end
