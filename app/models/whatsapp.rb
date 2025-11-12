#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "shellwords"
require "date"

class Whatsapp
  # Move "WhatsApp Chat -*.zip" from ~/Downloads to ./whatsapp_chats,
  # unzip them there, rename the extracted files to include the person's name.
  def self.prepare_whatsapp_chats(downloads: "/Users/hgtesta/Downloads", dest_dir: "whatsapp_chats")
    puts "Preparing WhatsApp chats..."
    FileUtils.mkdir_p(dest_dir)
    puts "Ensured destination directory: #{dest_dir}"

    zips = Dir.glob(File.join(downloads, "WhatsApp Chat -*.zip")).sort
    if zips.empty?
      puts 'No zips found matching "WhatsApp Chat -*.zip".'
      return
    end

    extracted = 0
    zips.each do |zip_path|
      moved_zip = File.join(dest_dir, File.basename(zip_path))
      puts "Moving and unzipping: #{zip_path} -> #{moved_zip}"
      FileUtils.mv(zip_path, moved_zip)

      unzip_ok = system("unzip", "-o", "-q", moved_zip, "-d", dest_dir)
      if unzip_ok
        extracted += 1

        # Extract person's name from the zip filename
        # Format: "WhatsApp Chat - Person Name.zip"
        basename = File.basename(moved_zip, ".zip")
        if basename =~ /WhatsApp Chat - (.+)/
          person_name = $1.strip

          # Rename _chat.txt to include person's name
          generic_chat = File.join(dest_dir, "_chat.txt")
          if File.exist?(generic_chat)
            person_chat = File.join(dest_dir, "chat_#{person_name}.txt")
            FileUtils.mv(generic_chat, person_chat)
            puts "Renamed _chat.txt to chat_#{person_name}.txt"
          end
        end
      else
        warn("Unzip failed for #{moved_zip}")
      end
    end

    puts "Done. Extracted #{extracted} zip(s) into #{dest_dir}."
  end

  # Read all files under ./whatsapp_chats and write every message
  # from a specific day to an output file.
  #
  # `date` can be a Date or something parsable by Date.parse (e.g., "2023-11-15", "11/15/2023").
  def self.write_chats_for_day(source_dir: "whatsapp_chats", date:, output_path:)
    target_date = date.is_a?(Date) ? date : Date.parse(date.to_s)
    puts "Scanning #{source_dir}..."
    puts "Target date: #{target_date}"

    ts_regex = /^\[(\d{1,2})\/(\d{1,2})\/(\d{2,4}),\s*\d{1,2}:\d{2}(?::\d{2})?(?:\s*(?:AM|PM))?\]/

    selected = []
    include_block = false
    blocks_today = 0
    total_files = 0
    current_file_has_content = false

    files = Dir.glob(File.join(source_dir, "**", "*.{txt,TXT}")).sort
    if files.empty?
      puts "No .txt files found under #{source_dir}."
      File.write(output_path, "")
      puts "Wrote empty output to #{output_path}."
      return
    end

    files.each do |file|
      total_files += 1
      file_selected_lines = 0
      current_file_has_content = false
      puts "Reading: #{file}"

      File.foreach(file, encoding: "UTF-8", chomp: false) do |raw|
        sanitized = raw.tr("\u202F\u00A0", " ").delete("\u200E\u200F")

        if (m = sanitized.match(ts_regex))
          mm, dd, yy = m.captures
          year_i = if yy.length == 2
                     yy_i = yy.to_i
                     yy_i >= 70 ? 1900 + yy_i : 2000 + yy_i
                   else
                     yy.to_i
                   end
          line_date = Date.new(year_i, mm.to_i, dd.to_i) rescue nil
          if line_date == target_date
            include_block = true
            blocks_today += 1
          else
            include_block = false
          end
        end

        if include_block
          # Add header for new file if this is the first message from this file
          if !current_file_has_content && file_selected_lines == 0
            contact_name = File.basename(file, ".*").gsub("_chat", "").gsub("chat_", "")
            selected << "\n=== #{contact_name} ===\n"
            current_file_has_content = true
          end
          selected << raw
          file_selected_lines += 1
        end
      end

      puts "  -> matched #{file_selected_lines} line(s) from this file."
      include_block = false
    end

    File.write(output_path, selected.join)
    puts "Matched #{blocks_today} message block(s) across #{total_files} file(s)."
    puts "Wrote #{selected.size} line(s) to: #{output_path}"

    # Also output the contents to console
    if selected.any?
      puts "\n#{selected.join}"
    else
      puts "\nNo messages found for this date."
    end
  end
end

# --- Main execution ---
if __FILE__ == $0
  if ARGV.empty?
    puts "Usage: ruby #{File.basename(__FILE__)} YYYY-MM-DD"
    puts "Example: ruby #{File.basename(__FILE__)} 2025-02-11"
    exit 1
  end

  date_arg = ARGV[0]

  # Check if date matches YYYY-MM-DD format
  unless date_arg.match?(/^\d{4}-\d{2}-\d{2}$/)
    puts "Error: Invalid date format '#{date_arg}'"
    puts "Please use YYYY-MM-DD format (e.g., 2025-02-11)"
    exit 1
  end

  begin
    parsed_date = Date.parse(date_arg)
    output_filename = "chats_#{date_arg}.txt"

    # Run the preparation and extraction
    Whatsapp.prepare_whatsapp_chats
    Whatsapp.write_chats_for_day(date: parsed_date, output_path: output_filename)
  rescue Date::Error => e
    puts "Error: Invalid date '#{date_arg}'"
    exit 1
  end
end
