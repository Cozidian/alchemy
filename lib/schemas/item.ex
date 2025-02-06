defmodule ALCHEMY.Schemas.Item do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  schema "items" do
    field(:chunk, :string)
    field(:embedding, Pgvector.Ecto.Vector)
    field(:metadata, :map)

    timestamps()
  end

  def changeset(item, attrs) do
    item
    |> cast(attrs, [:chunk, :embedding, :metadata])
    |> validate_required([:chunk, :embedding])
  end

  def search_chunk(_query, vector) do
    from(i in __MODULE__,
      order_by: fragment("embedding <-> ?", ^vector),
      # hardcoded limit for now
      limit: 5,
      select: %{
        content: i.chunk,
        similarity: fragment("1 - (embedding <-> ?)", ^vector)
      }
    )
  end
end
