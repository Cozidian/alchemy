defmodule ALCHEMY.LlmQueryServer do
  use GenServer
  require Logger

  @default_timeout 30_000

  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def query(prompt, timeout \\ @default_timeout) do
    GenServer.call(__MODULE__, {:query, prompt}, timeout)
  end

  def init(opts) do
    ollama_api = Keyword.get(opts, :ollama_api, "http://localhost:11434/api/generate")
    {:ok, %{ollama_api: ollama_api}}
  end

  def handle_call({:query, prompt}, _from, state) do
    response = query_ollama(prompt, state.ollama_api)
    {:reply, response, state}
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
