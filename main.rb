# rubocop:disable all
require_relative 'lib/segment'

# frozen_string_literal: true

# Main application class that will wrap the whole app
class MainApp
  def self.run
    new.run
  end

  def run
    input_file = ARGV[0]

    if input_file.nil?
      puts 'Warning: No input file provided'
      exit 1
    end

    # Step 1: read file and get segments from content
    input_file_content = File.read(input_file)
    
    segment_lines = []
    
    input_file_content.each_line do |line|
      line = line.strip
      next if line.empty?

      if line.start_with?('SEGMENT:')
        segment_lines << line
      else
        # Skip invalid lines but log them
        $stderr.puts "Warning: Skipping invalid line: #{line}" if ENV['DEBUG']
      end
    end

    puts segment_lines

    # Step 2: create segments from content
    segments = segment_lines.map { |line| Segment.parse(line) }

    puts segments
  end
end

# Run the whole app when the file is executed directly
MainApp.run if __FILE__ == $PROGRAM_NAME
