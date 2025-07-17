# frozen_string_literal: true
# rubocop:disable all

require_relative 'segment'
require_relative 'trip'

class ItineraryProcessor
  IATA_CODE_REGEX = /^[A-Z]{3}$/.freeze

  # Initialize the processor with the base IATA code
  def initialize(base_airport)
    @base_airport = base_airport

    validate_iata(@base_airport)
  end

  def process_file(file_path)
    # Step 1: read file and get segments from content
    segment_lines = read_segments(file_path)

    # Step 2: create segments from content
    segments = segment_lines.map { |line| Segment.parse(line) }

    # Step 3: Build trips from segments
    trips = Trip.group_segments(segments, @base_airport)

    # Step 4: Return trips
    trips
  end

  def display_trips(trips)
    trips.each { |trip| puts trip.to_s, '' }
  end

  private

  # Read the file and return an array of segment lines
  def read_segments(file_path)
    input_file_content = File.read(file_path)

    segment_lines = []
      
    input_file_content.each_line do |line|
      line = line.strip
      next if line.empty?

      segment_lines << line if line.start_with?('SEGMENT:')
    end

    segment_lines
  end

  # Validate the IATA code
  def validate_iata(iata_code)
    raise ItineraryErrors::InvalidIataCodeError, "IATA code is required" if iata_code.nil? || iata_code.empty?

    unless iata_code.match?(IATA_CODE_REGEX)
      raise ItineraryErrors::InvalidIataCodeError, "Invalid IATA code: #{iata_code}"
    end
  end
end
