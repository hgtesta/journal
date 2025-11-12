# Read all Logseq entries and output a single MD file for importing in DayOne. Instructions.
# 1) Ruby this script: ruby import.rb
# 2) Open Dayone and import 000.txt
#
# I started to write in Logseg on May, 7th, 2022

require "date"

# LOGSEQ_PATH  = "/Users/hgtesta/Library/Mobile\ Documents/com~apple~CloudDocs/logseq-data/journals-export"
# LOGSEQ_PATH = "/Users/hgtesta/Library/Mobile\ Documents/com~apple~CloudDocs/logseq-data/journals"
LOGSEQ_PATH = "Users/hgtesta/Library/Mobile Documents/com~apple~CloudDocs/logseq-data/journals"

# Dayone imports from a single md file. It should follow a specific syntax.
OUTPUT_FILENAME = "000.txt"

class Dayone
  def logseq_to_dayone
    # Delete the output file if it exists
    output_file_path = File.join(LOGSEQ_PATH, OUTPUT_FILENAME)
    File.delete(output_file_path) if File.exist?(output_file_path)

    each_entry do |entry|
      puts entry[:filename]

      formatted_date = entry[:date].strftime("%-d %B %Y at %H:%M:%S GMT-3")
      content = "\tDate:\t#{formatted_date}\n\n#{entry[:content]}\n\n"

      next if content.strip.empty?

      # Append mode to add to existing file (or create if doesn't exist)
      File.open(output_file_path, 'a') do |file|
        file.write(content)
      end
    end
  end

  # def extract_humor
  #   humor_entries = []

  #   # Regex pattern to match H: followed by ratings 1, 1.5, 2, 2.5, 3, 3.5, 4, 4.5
  #   # Uses non-greedy matching to capture the first H: occurrence
  #   humor_pattern = /.*?H:\s*(1(?:\.5)?|2(?:\.5)?|3(?:\.5)?|4(?:\.5)?)\b/

  #   each_entry do |entry|
  #     entry[:content].lines.each do |line|
  #       if match = line.match(humor_pattern)
  #         humor_entries << {
  #           date: entry[:date],
  #           humor: match[1].to_f,
  #           line: line.strip
  #         }
  #       end
  #     end
  #   end

  #   humor_entries
  # end

  def to_csv(filename = nil)
    output_lines = extract_humor.map do |entry|
      "#{entry[:date].strftime('%Y-%m-%d')},#{entry[:humor]}"
    end

    if filename
      File.write(filename, output_lines.join("\n") + "\n")
      puts "CSV data written to #{filename}"
    else
      output_lines.each { |line| puts line }
    end
  end
end

# To run the script
dayone = Dayone.new
# dayone.logseq_to_dayone

# Test to_csv method - save to file
dayone.to_csv("humor_data.csv")
