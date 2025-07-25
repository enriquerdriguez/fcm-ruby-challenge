# frozen_string_literal: true

require 'date'
require_relative 'errors'

# Represents a single travel segment (flight, train, hotel)
class Segment
  include ItineraryErrors

  attr_reader :type, :departure_airport, :arrival_airport, :departure_time, :arrival_time, :check_in_date,
              :check_out_date

  SEGMENT_TYPES = %w[Flight Train Hotel].freeze
  IATA_CODE_REGEX = /\A[A-Z]{3}\z/

  def initialize(attributes = {})
    @type = attributes[:type]
    @departure_airport = attributes[:departure_airport]
    @arrival_airport = attributes[:arrival_airport]
    @departure_time = attributes[:departure_time]
    @arrival_time = attributes[:arrival_time]
    @check_in_date = attributes[:check_in_date]
    @check_out_date = attributes[:check_out_date]

    validate!
  end

  # Parse a segment from a line
  def self.parse(line)
    # Expected format: "SEGMENT: Flight SVQ 2023-03-02 06:40 -> BCN 09:10"
    # or "SEGMENT: Hotel BCN 2023-01-05 -> 2023-01-10"
    validate_segment_line(line)
    parts = line.split('SEGMENT:').last.strip.split
    type = parts[0]

    # TODO: refactor this to use a factory pattern
    case type
    when 'Flight', 'Train'
      parse_transport_segment(parts)
    when 'Hotel'
      parse_hotel_segment(parts)
    else
      raise InvalidSegmentError, "Unsupported segment type: #{type}"
    end
  end

  def self.validate_segment_line(line)
    raise InvalidSegmentError, "Invalid segment format: #{line}" unless line.start_with?('SEGMENT:')

    parts = line.split('SEGMENT:').last.strip.split
    type = parts[0]

    raise InvalidSegmentError, "Invalid segment type: #{type}" unless SEGMENT_TYPES.include?(type)
  end

  # Check if the segment is a transport segment
  def transport?
    %w[Flight Train].include?(@type)
  end

  # Check if the segment is a hotel segment
  def hotel?
    @type == 'Hotel'
  end

  # Get the departure date
  def departure_date
    @departure_time&.to_date
  end

  # Get the arrival date
  def arrival_date
    @arrival_time&.to_date
  end

  # Return a string representation of the segment
  def to_s
    if transport?
      "#{@type} from #{@departure_airport} to #{@arrival_airport} at #{format_datetime(@departure_time)} to #{format_time(@arrival_time)}"
    else
      "Hotel at #{@arrival_airport} on #{format_date(@check_in_date)} to #{format_date(@check_out_date)}"
    end
  end

  # Sort segments by date
  def self.sort_by_date(segments)
    segments.sort_by do |segment|
      if segment.transport?
        segment.departure_time
      else
        segment.check_in_date.to_datetime
      end
    end
  end

  # Parse a transport segment and creates an instance of Segment
  def self.parse_transport_segment(parts)
    # Format: "Flight SVQ 2023-03-02 06:40 -> BCN 09:10"
    attributes = extract_transport_attributes(parts)

    create_segment(attributes)
  end

  # Parse a hotel segment and creates an instance of Segment
  def self.parse_hotel_segment(parts)
    # Format: "Hotel BCN 2023-01-05 -> 2023-01-10"
    attributes = extract_hotel_attributes(parts)

    create_segment(attributes)
  end

  # Method to extract the attributes for a transport segment
  def self.extract_transport_attributes(parts)
    date_str = parts[2]
    time_str = parts[3]
    arrival_time_str = parts[6]

    departure_time = parse_datetime("#{date_str} #{time_str}")
    arrival_time = parse_datetime("#{date_str} #{arrival_time_str}")

    # Handle overnight flights
    arrival_time += 1 if arrival_time < departure_time

    {
      type: parts[0],
      departure_airport: parts[1],
      arrival_airport: parts[5],
      departure_time: departure_time,
      arrival_time: arrival_time
    }
  end

  # Method to extract the attributes for a hotel segment
  def self.extract_hotel_attributes(parts)
    {
      type: parts[0],
      arrival_airport: parts[1],
      check_in_date: parse_date(parts[2]),
      check_out_date: parse_date(parts[4])
    }
  end

  # Parse a datetime string and creates an instance of DateTime
  def self.parse_datetime(datetime_str)
    raise "Datetime cannot be nil: #{datetime_str}" if datetime_str.nil?

    DateTime.parse(datetime_str)
  rescue ArgumentError => e
    raise DateTimeParseError, "Invalid datetime format: #{datetime_str} - #{e.message}"
  end

  # Parse a date string and creates an instance of Date
  def self.parse_date(date_str)
    raise DateTimeParseError, 'Invalid date format for nil' if date_str.nil?

    Date.parse(date_str)
  rescue ArgumentError => e
    raise DateTimeParseError, "Invalid date format: #{date_str} - #{e.message}"
  end

  def self.create_segment(attributes)
    new(attributes)
  end

  def self.overnight_flight?(departure_time, arrival_time)
    arrival_time < departure_time
  end

  private

  # Format a datetime to a string
  def format_datetime(datetime)
    datetime.strftime('%Y-%m-%d %H:%M')
  end

  # Format a time to a string
  def format_time(datetime)
    datetime.strftime('%H:%M')
  end

  # Format a date to a string
  def format_date(date)
    date.strftime('%Y-%m-%d')
  end

  # Validations for Segment creation
  def validate!
    validate_type
    validate_airports
    validate_times
  end

  # Validate the type of the segment
  def validate_type
    return if SEGMENT_TYPES.include?(@type)

    raise InvalidSegmentError, "Invalid segment type: #{@type}"
  end

  # Validate the airports of the segment
  def validate_airports
    if transport?
      validate_iata_code(@departure_airport, 'departure_airport')
      validate_iata_code(@arrival_airport, 'arrival_airport')
    elsif hotel?
      validate_iata_code(@arrival_airport, 'arrival_airport')
    end
  end

  # Validate the IATA code of the segment
  def validate_iata_code(code, field_name)
    return if code.nil?
    return if code.match?(IATA_CODE_REGEX)

    raise InvalidSegmentError, "Invalid #{field_name}: #{code}"
  end

  def existing_departure_and_arrival_time?
    @departure_time.nil? || @arrival_time.nil?
  end

  def existing_check_in_and_check_out_date?
    @check_in_date.nil? || @check_out_date.nil?
  end

  def check_in_date_before_check_out_date?
    @check_in_date >= @check_out_date
  end

  # Validate the times of the segment
  def validate_times
    if transport?
      raise InvalidSegmentError, 'Transport segments must have departure and arrival times' if existing_departure_and_arrival_time?
    elsif hotel?
      raise InvalidSegmentError, 'Hotel segments must have check-in and check-out dates' if existing_check_in_and_check_out_date?

      raise InvalidSegmentError, 'Check-in date must be before check-out date' if check_in_date_before_check_out_date?
    end
  end
end
