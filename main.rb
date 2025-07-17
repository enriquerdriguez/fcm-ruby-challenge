# rubocop:disable all
require_relative 'lib/segment'
require_relative 'lib/trip'
require 'pry'

# frozen_string_literal: true

# Main application class that will wrap the whole app
class MainApp
  IATA_CODE_REGEX = /^[A-Z]{3}$/.freeze

  def self.run
    new.run
  end

  def run
    input_file = ARGV[0]

    if input_file.nil?
      puts 'Warning: No input file provided'
      exit 1
    end

    begin
      # Step 1: read file and get segments from content
      input_file_content = File.read(input_file)
      base_airport = ENV['BASED']
      validate_iata(base_airport)
      
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

      # Step 2: create segments from content
      segments = segment_lines.map { |line| Segment.parse(line) }

      # Step 3: Build trips from segments
      trips = Trip.group_segments(segments, base_airport)

      puts trips

    rescue ItineraryErrors::ItineraryError => e
      puts "Unexpected Error: #{e.message}"
      exit 1
    end


  end

  private
  def validate_iata(iata_code)
    raise ItineraryErrors::InvalidIataCodeError, "IATA code is required" if iata_code.nil? || iata_code.empty?

    unless iata_code.match?(IATA_CODE_REGEX)
      raise ItineraryErrors::InvalidSegmentError, "Invalid IATA code: #{iata_code}"
    end
  end
end

# Run the whole app when the file is executed directly
MainApp.run if __FILE__ == $PROGRAM_NAME
