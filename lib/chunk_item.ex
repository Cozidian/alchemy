defmodule ALCHEMY.ChunkItem do
  @type t :: %__MODULE__{
          chunk: String.t(),
          meta_data: {String.t(), String.t()} | nil,
          timestamp: DateTime.t()
        }

  defstruct [:chunk, :meta_data, :timestamp]
end
