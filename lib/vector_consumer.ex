defmodule ALCHEMY.Consumers.VectorConsumer do
  use GenStage
  alias ALCHEMY.Repo
  alias ALCHEMY.Schemas.Item

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
    Enum.each(processed_chunks, fn chunk ->
      case chunk.meta_data do
        {"embedding", embedding_data} ->
          case extract_embedding(embedding_data) do
            nil ->
              require Logger
              Logger.warn("Embedding data missing actual embedding: #{inspect(embedding_data)}")

            embedding ->
              changeset =
                Item.changeset(%Item{}, %{
                  chunk: chunk.chunk,
                  embedding: Pgvector.new(embedding),
                  metadata: Map.drop(embedding_data, ["embedding", "embeddings"])
                })

              Repo.insert!(changeset)
          end

        _ ->
          require Logger
          Logger.warn("Received chunk without valid embedding data: #{inspect(chunk)}")
      end
    end)

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
