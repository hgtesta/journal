class Entry < ApplicationRecord
  include EntryImporter

  has_neighbors :embedding

  scope :semantic_search, ->(query, limit: 20) {
    query_vec = RubyLLM.embed(query).vectors
    nearest_neighbors(:embedding, query_vec, distance: "cosine").limit(limit)
  }
  # neighbor_distance

  def self.search_content(query, limit: 20)
    semantic_search(query, limit:).pluck(:date, :content)
  end

  def self.on_date(date_as_string)
    date = DateTime.parse(date_as_string)
    where(date:)
  end

  def self.generate_embedding
    puts
    Entry.where.not(embedding: nil).in_batches(of: 100) do |entries_batch|
      contents = entries_batch.pluck(:content)
      vectors = RubyLLM.embed(contents).vectors
      puts "*"
      entries_batch.each_with_index do |entry, index|
        entry.update(embedding: vectors[index])
        print "."
      end
      puts
    end
  end

  def generate_embedding
    return if content.blank?

    begin
      embedding_result = RubyLLM.embed(content) # Uses default embedding model
      self.embedding = embedding_result.vectors
      save!
    rescue RubyLLM::Error => e
      errors.add(:base, "Failed to generate embedding: #{e.message}")
      # Prevent saving if embedding fails (optional, depending on requirements)
      throw :abort
    end
  end
end
