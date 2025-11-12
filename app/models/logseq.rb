require 'fileutils'

class Logseq
  LOGSEQ_PATH = "/Users/hgtesta/Library/Mobile Documents/com~apple~CloudDocs/logseq-data/journals"

  def self.import_entries
    FileUtils.mkdir_p('entries')
    Dir.glob("#{LOGSEQ_PATH}/*").each do |file|
      if File.file?(file)
        destination = File.join('data/entries', File.basename(file))
        FileUtils.cp(file, destination) unless File.exist?(destination)
      end
    end
  end

  # Iterate over entries
  def each_entry
    Dir.entries(LOGSEQ_PATH)
       .select { |entry| File.file?(File.join(LOGSEQ_PATH, entry)) }
       .sort
       .each do |filename|
         next if filename == ".DS_Store"
         next if filename == ".git"
         next unless filename.match(/^\d{4}_\d{2}_\d{2}\.md$/)

         file_path = File.join(LOGSEQ_PATH, filename)
         content = File.read(file_path)

         # Remove lines starting with 'title::'
         content = content.lines.reject { |line| line.strip.start_with?('title::') }.join
         year, month, day = filename.gsub('.md', '').split('_')
         date = DateTime.new(year.to_i, month.to_i, day.to_i, 12, 0, 0, "-3")

         entry = { filename:, date:, content: }

         yield entry
       end
  end
end

Logseq.import_entries
