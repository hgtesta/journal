class Entry < ApplicationRecord
  # Regex pattern to match H: followed by ratings 1, 1.5, 2, 2.5, 3, 3.5, 4, 4.5
  # Uses non-greedy matching to capture the first H: occurrence
  HUMOR_PATTERN = /.*?H:\s*(1(?:\.5)?|2(?:\.5)?|3(?:\.5)?|4(?:\.5)?)\b/

  def self.each_stored
    Dir.entries('data/entries')
       .select { |entry| File.file?(File.join('data/entries', entry)) }
       .sort
       .each do |filename|
         next if filename == ".DS_Store"
         next if filename == ".git"
         next unless filename.match(/^\d{4}_\d{2}_\d{2}\.md$/)

         file_path = File.join('data/entries', filename)
         content = File.read(file_path)

         # Remove lines starting with 'title::'
         content = content.lines.reject { |line| line.strip.start_with?('title::') }.join
         year, month, day = filename.gsub('.md', '').split('_')
         date = DateTime.new(year.to_i, month.to_i, day.to_i, 12, 0, 0, "-3")

         entry = { filename:, date:, content: }

         yield entry
       end
  end

  def self.store
    each_stored do |entry|
      humor, humor_line = extract_humor(entry[:content])
      create!(
        humor:,
        humor_line:,
        date: entry[:date],
        content: entry[:content]
      )
    end
  end

  def self.extract_humor(content)
    each_stored do |entry|
      entry[:content].lines.each do |line|
        if match = line.match(HUMOR_PATTERN)
          return { humor: match[1].to_f, humor_line: line.strip }
        end
      end
    end
  end
end
