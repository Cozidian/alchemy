defmodule ALCHEMY.ProducerConsumers.EmbeddingProcessor do
  use GenStage
  use HTTPoison.Base
  require Logger

  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenStage.start_link(__MODULE__, opts, name: name)
  end

  def init(opts) do
    embedding_api = Keyword.get(opts, :embedding_api, "")

    subscribe_to = Keyword.get(opts, :subscribe_to, [ALCHEMY.ProducerConsumers.TextProcessor])

    {:producer_consumer, %{embedding_api: embedding_api}, subscribe_to: subscribe_to}
  end

  def handle_events(chunks, _from, state) do
    processed_chunks =
      Enum.map(chunks, fn chunk ->
        body =
          Jason.encode!(%{
            "model" => "mxbai-embed-large",
            "input" => chunk.chunk
          })

        headers = [{"Content-Type", "application/json"}]

        with {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} <-
               HTTPoison.post(state.embedding_api, body, headers),
             {:ok, decoded_response} <-
               Jason.decode(response_body) do
          %{chunk | meta_data: {"embedding", decoded_response}}
        else
          {:ok, %HTTPoison.Response{status_code: status_code}} ->
            Logger.error("Embedding API returned status code: #{status_code}")
            chunk

          {:error, %HTTPoison.Error{reason: reason}} ->
            Logger.error("Failed to embed chunk: #{Exception.message(reason)}")
            chunk

          {:error, error} ->
            Logger.error("Failed to decode Ollama response: #{inspect(error)}")
            {:error, :invalid_response}
        end
      end)

    {:noreply, processed_chunks, state}
  end
end
