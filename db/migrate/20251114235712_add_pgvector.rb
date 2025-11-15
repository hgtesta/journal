class AddPgvector < ActiveRecord::Migration[8.1]
  def change
    enable_extension 'vector'
    add_column :entries, :embedding, :vector, limit: 1536
    execute <<~SQL
      CREATE INDEX index_entries_on_embedding_hnsw
      ON entries USING hnsw (embedding vector_cosine_ops);
    SQL
  end
end
