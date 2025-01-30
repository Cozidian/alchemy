defmodule ALCHEMY.FileItem do
  @type t :: %__MODULE__{
          filename: String.t(),
          filelocation: String.t(),
          timestamp: DateTime.t()
        }

  defstruct [:filename, :filelocation, :timestamp]
end
