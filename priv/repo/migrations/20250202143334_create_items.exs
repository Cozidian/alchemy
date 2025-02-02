defmodule ALCHEMY.Repo.Migrations.CreateItems do
  use Ecto.Migration

  def up do
    execute("CREATE EXTENSION IF NOT EXISTS vector")

    create table(:items) do
      add :chunk, :text
      add :embedding, :vector, size: 1024
      add :metadata, :map

      timestamps()
    end

    execute("""
    CREATE INDEX items_embedding_index ON items 
    USING hnsw (embedding vector_l2_ops) 
    WITH (m = 16, ef_construction = 64)
    """)
  end

  def down do
    drop table(:items)
    execute("DROP EXTENSION vector")
  end
end
