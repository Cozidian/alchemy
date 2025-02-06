defmodule ALCHEMY.LlmQueryServer do
  use GenServer
  require Logger

  @default_timeout 30_000
  @chat_url "http://localhost:11434/api/chat"

  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def query(prompt, timeout \\ @default_timeout) do
    GenServer.call(__MODULE__, {:query, prompt}, timeout)
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

    case HTTPoison.post(ollama_api, body, headers, recv_timeout: @default_timeout) do
      {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} ->
        case Jason.decode(response_body) do
          {:ok, decoded} ->
            {:ok, Map.get(decoded, "response")}

          {:error, error} ->
            Logger.error("Failed to decode Ollama response: #{inspect(error)}")
            {:error, :invalid_response}
        end

      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        Logger.error("Ollama API returned #{status_code}: #{body}")
        {:error, :api_error}

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("Failed to query Ollama: #{inspect(reason)}")
        {:error, reason}
    end
  end
end
