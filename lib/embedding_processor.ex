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

        case HTTPoison.post(state.embedding_api, body, headers) do
          {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} ->
            case Jason.decode(response_body) do
              {:ok, decoded_response} ->
                %{chunk | meta_data: {"embedding", decoded_response}}

              {:error, decode_error} ->
                Logger.error("Failed to decode response: #{inspect(decode_error)}")
                chunk
            end

          {:ok, %HTTPoison.Response{status_code: status_code}} ->
            Logger.error("Embedding API returned status code: #{status_code}")
            chunk

          {:error, %HTTPoison.Error{reason: reason}} ->
            Logger.error("Failed to embed chunk: #{Exception.message(reason)}")
            chunk
        end
      end)

    {:noreply, processed_chunks, state}
  end
end
