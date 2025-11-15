module EntryImporter
  extend ActiveSupport::Concern

  # Regex pattern to match H: followed by ratings 1, 1.5, 2, 2.5, 3, 3.5, 4, 4.5
  # Uses non-greedy matching to capture the first H: occurrence
  HUMOR_PATTERN = /.*?H:\s*(1(?:\.5)?|2(?:\.5)?|3(?:\.5)?|4(?:\.5)?)\b/

  class_methods do
    # Iterate over each file in the data/entries directory
    def each_file
      Dir.entries('data/entries')
         .select { |entry| File.file?(File.join('data/entries', entry)) }
         .sort
         .each do |filename|
           next if filename == ".DS_Store"
           next if filename == ".git"
           next unless filename.match(/^\d{4}_\d{2}_\d{2}\.md$/)

           file_path = File.join('data/entries', filename)
           content = File.read(file_path)

           yield filename, content
         end
    end

    def parse_file(filename, content)
      # Get date from filename
      year, month, day = filename.gsub('.md', '').split('_')
      date = DateTime.new(year.to_i, month.to_i, day.to_i, 12, 0, 0, "-3")

      # Remove lines starting with 'title::'
      content = content.lines.reject { |line| line.strip.start_with?('title::') }.join

      # Get humor from content
      humor, humor_line = extract_humor(content)

      new(
        humor: humor,
        humor_line: humor_line&.gsub("\u0000", ''),
        date: date,
        content: content&.gsub("\u0000", '')
      )
    end

    def import_all
      each_file do |filename, content|
        import(filename, content)
      end
    end

    def import(filename, content)
      entry = parse_file(filename, content)
      entry.save!
    end

    def extract_humor(content)
      content.lines.each do |line|
        if match = line.match(HUMOR_PATTERN)
          return [match[1].to_f, line.strip]
        end
      end
      [nil, nil]
    end
  end

  def extract_humor
    Entry.extract_humor(content)
  end
end

Entry.where(humor: nil).all.each do |entry|
  humor, humor_line = entry.extract_humor
  entry.update humor:, humor_line:
end
