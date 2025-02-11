defmodule ALCHEMY.Consumers.VectorConsumer do
  use GenStage
  alias ALCHEMY.Repo
  alias ALCHEMY.Schemas.Item
  require Logger

  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenStage.start_link(__MODULE__, opts, name: name)
  end

  @impl true
  def init(opts) do
    subscribe_to =
      Keyword.get(opts, :subscribe_to, [ALCHEMY.ProducerConsumers.EmbeddingProcessor])

    {:consumer, :ok, subscribe_to: subscribe_to}
  end

  @impl true
  def handle_events(processed_chunks, _from, state) do
    Logger.info("Recieved #{length(processed_chunks)} chunks to process")

    results =
      Enum.map(processed_chunks, fn chunk ->
        with {"embedding", embedding_data} <- chunk.meta_data,
             embedding when not is_nil(embedding) <- extract_embedding(embedding_data),
             changeset =
               Item.changeset(%Item{}, %{
                 chunk: chunk.chunk,
                 embedding: Pgvector.new(embedding),
                 metadata: Map.drop(embedding_data, ["embedding", "embeddings"])
               }),
             {:ok, item} <- Repo.insert(changeset) do
          {:ok, item}
        else
          nil ->
            Logger.warning("Embedding data missing actual embedding: #{inspect(chunk.meta_data)}")
            {:error, :missing_embedding}

          {:error, error} ->
            Logger.error("Failed to insert chunk: #{inspect(error)}")
            {:error, error}

          other ->
            Logger.warning("Received chunk without valid embedding data: #{inspect(chunk)}")
            other
        end
      end)

    successful =
      Enum.count(results, fn
        {:ok, _} -> true
        _ -> false
      end)

    Logger.info("Successfully processed #{successful} out of #{length(processed_chunks)}")

    {:noreply, [], state}
  end

  defp extract_embedding(embedding_data) do
    cond do
      Map.has_key?(embedding_data, "embedding") and embedding_data["embedding"] != nil ->
        embedding_data["embedding"]

      Map.has_key?(embedding_data, "embeddings") and is_list(embedding_data["embeddings"]) ->
        List.first(embedding_data["embeddings"])

      true ->
        nil
    end
  end
end
