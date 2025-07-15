# frozen_string_literal: true
# rubocop:disable all

require 'date'
require_relative 'errors'

# Represents a single travel segment (flight, train, hotel)
class Segment
  include ItineraryErrors

  attr_reader :type, :departure_airport, :arrival_airport, :departure_time, :arrival_time, :check_in_date, :check_out_date

  SEGMENT_TYPES = %w[Flight Train Hotel].freeze
  IATA_CODE_REGEX = /\A[A-Z]{3}\z/

  def initialize(type:, departure_airport: nil, arrival_airport: nil, 
                 departure_time: nil, arrival_time: nil, 
                 check_in_date: nil, check_out_date: nil)
    @type = type
    @departure_airport = departure_airport
    @arrival_airport = arrival_airport
    @departure_time = departure_time
    @arrival_time = arrival_time
    @check_in_date = check_in_date
    @check_out_date = check_out_date

    validate!
  end

  def self.parse(line)
    # Expected format: "SEGMENT: Flight SVQ 2023-03-02 06:40 -> BCN 09:10"
    # or "SEGMENT: Hotel BCN 2023-01-05 -> 2023-01-10"
    
    unless line.start_with?('SEGMENT:')
      raise InvalidSegmentError, "Invalid segment format: #{line}"
    end

    parts = line.split('SEGMENT:').last.strip.split
    type = parts[0]

    unless SEGMENT_TYPES.include?(type)
      raise InvalidSegmentError, "Invalid segment type: #{type}"
    end

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

  def transport?
    %w[Flight Train].include?(@type)
  end

  def hotel?
    @type == 'Hotel'
  end

  def departure_date
    @departure_time&.to_date
  end

  def arrival_date
    @arrival_time&.to_date
  end

  def to_s
    if transport?
      "#{@type} from #{@departure_airport} to #{@arrival_airport} at #{format_datetime(@departure_time)} to #{format_time(@arrival_time)}"
    else
      "Hotel at #{@arrival_airport} on #{format_date(@check_in_date)} to #{format_date(@check_out_date)}"
    end
  end

  private

  def self.parse_transport_segment(parts)
    # Format: "Flight SVQ 2023-03-02 06:40 -> BCN 09:10"
    type = parts[0]
    departure_airport = parts[1]
    date_str = parts[2]
    time_str = parts[3]
    arrival_airport = parts[5]
    arrival_time_str = parts[6]

    departure_time = parse_datetime("#{date_str} #{time_str}")
    arrival_time = parse_datetime("#{date_str} #{arrival_time_str}")

    # Handle overnight flights
    if arrival_time < departure_time
      arrival_time += 1.day
    end

    new(
      type: type,
      departure_airport: departure_airport,
      arrival_airport: arrival_airport,
      departure_time: departure_time,
      arrival_time: arrival_time
    )
  end

  def self.parse_hotel_segment(parts)
    # Format: "Hotel BCN 2023-01-05 -> 2023-01-10"
    type = parts[0]
    airport = parts[1]
    check_in_date = parse_date(parts[2])
    check_out_date = parse_date(parts[4])

    new(
      type: type,
      arrival_airport: airport,
      check_in_date: check_in_date,
      check_out_date: check_out_date
    )
  end

  def self.parse_datetime(datetime_str)
    raise "Datetime cannot be nil: #{datetime_str}" if datetime_str.nil?
    
    DateTime.parse(datetime_str)
  rescue ArgumentError => e
    raise DateTimeParseError, "Invalid datetime format: #{datetime_str} - #{e.message}"
  end

  def self.parse_date(date_str)
    raise DateTimeParseError, "Invalid date format for nil" if date_str.nil?
    
    Date.parse(date_str)
  rescue ArgumentError => e
    raise DateTimeParseError, "Invalid date format: #{date_str} - #{e.message}"
  end

  def format_datetime(datetime)
    datetime.strftime('%Y-%m-%d %H:%M')
  end

  def format_time(datetime)
    datetime.strftime('%H:%M')
  end

  def format_date(date)
    date.strftime('%Y-%m-%d')
  end

  def validate!
    validate_type
    validate_airports
    validate_times
  end

  def validate_type
    unless SEGMENT_TYPES.include?(@type)
      raise InvalidSegmentError, "Invalid segment type: #{@type}"
    end
  end

  def validate_airports
    if transport?
      validate_iata_code(@departure_airport, 'departure_airport')
      validate_iata_code(@arrival_airport, 'arrival_airport')
    elsif hotel?
      validate_iata_code(@arrival_airport, 'arrival_airport')
    end
  end

  def validate_iata_code(code, field_name)
    return if code.nil?
    unless code.match?(IATA_CODE_REGEX)
      raise InvalidSegmentError, "Invalid #{field_name}: #{code}"
    end
  end

  def validate_times
    if transport?
      if @departure_time.nil? || @arrival_time.nil?
        raise InvalidSegmentError, "Transport segments must have departure and arrival times"
      end
    elsif hotel?
      if @check_in_date.nil? || @check_out_date.nil?
        raise InvalidSegmentError, "Hotel segments must have check-in and check-out dates"
      end
      
      if @check_in_date >= @check_out_date
        raise InvalidSegmentError, "Check-in date must be before check-out date"
      end
    end
  end
end
