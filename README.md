# ALCHEMY

This is a project I have used for learning about running LLM locally with the ability to extend the LLM cutoff knowledge. This should be fine to run on your own device as long as you choose a LLM model fitting you local specs.

This is not meant for production, but feel free to clone or fork it and make the adjustments you need for the purpose you need.

## How to use it

```bash
git clone
```

pull down the dependencies needed

```bash
mix get.deps
```

compile the project

```bash
mix compile
```

run the project in interactive mode

```bash
iex -S mix
```

call the function with the text you want to generate a completion for

```elixir
ALCHEMY.LlmQueryServer.stream("What is my name?")
```

````elixir

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `alchemy` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:alchemy, "~> 0.1.0"}
  ]
end
````

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/alchemy>.
