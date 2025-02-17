# ALCHEMY

This is a project I have used for learning about running LLM locally with the ability to extend the LLM cutoff knowledge. This should be fine to run on your own device as long as you choose a LLM model fitting you local specs.

This is not meant for production, but feel free to clone or fork it and make the adjustments you need for the purpose you need.

## Quick Start

> [!IMPORTANT]
> You need to have elixir 1.18 and erlang 27 installed on your machine.

```bash
# pull down the dependencies
mix get.deps
```

```bash
# compile the project
mix compile
```

```bash
# run the project
iex -S mix
```

```elixir
# run a query (without streaming response)
ALCHEMY.LlmQueryServer.query("hello")

# run a query with added context (without streaming response)
ALCHEMY.LlmQueryServer.query_with_context("hello")

# run a query with streaming response
ALCHEMY.LlmQueryServer.stream("What is my name?")

# run a query with added context and streaming response
ALCHEMY.LlmQueryServer.stream_with_context("What is my name?")
```

## Adding context

You do this simply as adding .txt files to the input folder. If the folder does not exist, you can create it.
