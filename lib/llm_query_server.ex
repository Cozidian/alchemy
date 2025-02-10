defmodule ALCHEMY.LlmQueryServer do
  use GenServer
  require Logger

  @default_timeout 30_000
  @chat_url "http://localhost:11434/api/chat"
  @embedding_url "http://localhost:11434/api/embed"

  def(start_link(opts)) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def query(prompt, timeout \\ @default_timeout) do
    GenServer.call(__MODULE__, {:query, prompt}, timeout)
  end

  def query_with_context(prompt, timeout \\ @default_timeout) do
    GenServer.call(__MODULE__, {:query_with_context, prompt}, timeout)
  end

  def stream_with_context(prompt) do
    GenServer.call(__MODULE__, {:stream_with_context, prompt}, 10_000)
  end

  def stream(prompt) do
    GenServer.call(__MODULE__, {:stream, prompt}, 10_000)
  end

  def init(opts) do
    ollama_api = Keyword.get(opts, :ollama_api, "http://localhost:11434/api/generate")
    {:ok, %{ollama_api: ollama_api}}
  end

  def handle_call({:query, prompt}, _from, state) do
    response = query_ollama(prompt, state.ollama_api)
    {:reply, response, state}
  end

  def handle_call({:query_with_context, prompt}, _from, state) do
    with {:ok, embedding} <- get_embedding(prompt),
         similar_chunks <- find_similar_chunks(embedding),
         context = build_context(similar_chunks),
         enriched_prompt = build_prompt_with_context(prompt, context),
         {:ok, response} <- query_ollama(enriched_prompt, state.ollama_api) do
      {:reply, {:ok, response}, state}
    else
      error -> {:reply, error, state}
    end
  end

  def handle_call({:stream_with_context, prompt}, _from, state) do
    with {:ok, embedding} <- get_embedding(prompt),
         similar_chunks <- find_similar_chunks(embedding),
         context = build_context(similar_chunks),
         enriched_prompt = build_prompt_with_context(prompt, context),
         {:ok, response} <- chat_with_model(enriched_prompt) do
      {:reply, {:ok, response}, state}
    else
      error -> {:reply, error, state}
    end
  end

  def handle_call({:stream, prompt}, _from, state) do
    chat_with_model(prompt)
    {:reply, :ok, state}
  end

  def chat_with_model(message) do
    ensure_dependencies_started()

    body =
      %{
        model: "llama3.2",
        messages: [
          %{role: "user", content: message}
        ]
      }
      |> Jason.encode!()

    headers = [{"Content-Type", "application/json"}]

    case HTTPoison.post(@chat_url, body, headers, stream_to: self()) do
      {:ok, async_response} ->
        stream_response(async_response)

      {:error, reason} ->
        IO.puts("Error making request: #{inspect(reason)}")
    end
  end

  defp get_embedding(text) do
    body =
      Jason.encode!(%{
        "model" => "mxbai-embed-large",
        "input" => text
      })

    headers = [{"Content-Type", "application/json"}]

    case HTTPoison.post(@embedding_url, body, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} ->
        case Jason.decode(response_body) do
          {:ok, decoded_response} ->
            # Extract the embedding from the decoded response
            case decoded_response do
              %{"embedding" => embedding} -> {:ok, embedding}
              %{"embeddings" => [embedding | _]} -> {:ok, embedding}
              response when is_list(response) -> {:ok, response}
              _ -> {:error, :invalid_embedding_response}
            end

          error ->
            error
        end

      {:ok, %HTTPoison.Response{status_code: status_code}} ->
        Logger.error("Embedding API returned status code: #{status_code}")
        {:error, :embedding_failed}

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("Failed to get embedding: #{inspect(reason)}")
        {:error, :embedding_failed}
    end
  end

  defp find_similar_chunks(embedding) do
    vector = Pgvector.new(embedding)

    ALCHEMY.Schemas.Item
    |> ALCHEMY.Schemas.Item.search_chunk(vector)
    |> ALCHEMY.Repo.all()
  end

  defp build_context(similar_chunks) do
    similar_chunks
    |> Enum.map_join("\n", & &1.content)
  end

  defp build_prompt_with_context(prompt, context) do
    """
    Context information:
    #{context}

    Based on the above context, please respond to:
    #{prompt}
    """
  end

  defp ensure_dependencies_started do
    {:ok, _} = Application.ensure_all_started(:hackney)
    {:ok, _} = Application.ensure_all_started(:httpoison)
  end

  defp stream_response(%{id: ref}) do
    receive_stream(ref)
    :ok
  end

  defp receive_stream(ref) do
    receive do
      %{id: ^ref, code: _code} ->
        receive_stream(ref)

      %{id: ^ref, headers: _headers} ->
        receive_stream(ref)

      %{id: ^ref, chunk: chunk} ->
        extracted_content =
          case Jason.decode(chunk) do
            {:ok, %{"message" => %{"content" => content}}} ->
              content

            _ ->
              chunk
          end

        IO.write(extracted_content)
        receive_stream(ref)

      msg = %{id: ^ref} ->
        if Map.has_key?(msg, :code) or Map.has_key?(msg, :headers) or Map.has_key?(msg, :chunk) do
          receive_stream(ref)
        else
          :ok
        end
    after
      30_000 ->
        IO.puts("Timeout reached")
        :ok
    end
  end

  defp query_ollama(prompt, ollama_api) do
    body =
      Jason.encode!(%{
        model: "llama3.2:latest",
        prompt: prompt,
        stream: false
      })

    headers = [{"Content-Type", "application/json"}]

    with {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} <-
           HTTPoison.post(ollama_api, body, headers, recv_timeout: @default_timeout),
         {:ok, decoded} <- Jason.decode(response_body) do
      {:ok, Map.get(decoded, "response")}
    else
      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        Logger.error("Ollama API returned #{status_code}: #{body}")
        {:error, :api_error}

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("Failed to query Ollama: #{inspect(reason)}")
        {:error, reason}

      {:error, error} ->
        Logger.error("Failed to decode Ollama response: #{inspect(error)}")
        {:error, :invalid_response}
    end
  end
end
