defmodule ALCHEMY.Schemas.Item do
  use Ecto.Schema
  import Ecto.Changeset

  schema "items" do
    field :chunk, :string
    field :embedding, Pgvector.Ecto.Vector
    field :metadata, :map

    timestamps()
  end

  def changeset(item, attrs) do
    item
    |> cast(attrs, [:chunk, :embedding, :metadata])
    |> validate_required([:chunk, :embedding])
  end
end
