# rubocop:disable all

require 'pry'
require_relative 'segment'

class Trip
  attr_reader :segments, :base_airport

  def initialize(segments:, base_airport:)
    @segments = segments
    @base_airport = base_airport
    @destination = determine_destination
  end

  def self.group_segments(segments, base_airport)
    return [] if segments.empty?
  
    # Sort all segments chronologically by start time to process them in order
    sorted = Segment.sort_by_date(segments)

    # each trip should start with a transport segment leaving the base IATA
    initial_point_segments = sorted.select { |segment| segment.departure_airport == base_airport }
    raise ItineraryErrors::InvalidTripError, "There are no segments that start from the base IATA #{base_airport}" if initial_point_segments.empty?

    sorted = sorted - initial_point_segments

    trips = []
    # Process each initial segment that starts from base airport
    initial_point_segments.each do |initial_segment|
      current_trip_segments = [initial_segment]
      current_segment = current_trip_segments.last
      current_location = current_segment.arrival_airport
      current_time = current_segment.transport? ? current_segment.arrival_time : current_segment.check_out_date.to_datetime

      # Keep looking for connected segments until we return to base or run out of segments
      while current_location != base_airport && !sorted.empty?
        # Find next segment that matches our current location and time
        next_segment = sorted.find do |segment|
          if segment.transport?
            segment.departure_airport == current_location && 
            segment.departure_time >= current_time
          else
            segment.arrival_airport == current_location &&
            segment.check_in_date >= current_time.to_date
          end
        end

        break unless next_segment

        # Add segment to trip and update current location/time
        current_trip_segments << next_segment
        sorted.delete(next_segment)

        if next_segment.transport?
          current_location = next_segment.arrival_airport
          current_time = next_segment.arrival_time
        else
          current_location = next_segment.arrival_airport
          current_time = next_segment.check_out_date.to_datetime
        end
      end

      # Add completed trip to trips array
      trips << Trip.new(segments: current_trip_segments, base_airport: base_airport)
    end

    # Order trips by earliest date
    trips.sort_by(&:earliest_date)
  end

  # Find the earliest date from all segments
  def earliest_date
    dates = @segments.map { |segment| segment.transport? ? segment.departure_time : segment.check_in_date }
    dates.min
  end

  # Return a string representation of the trip
  def to_s
    return if @segments.empty?

    lines = ["TRIP to #{@destination}"]
    @segments.each do |segment|
      lines << segment.to_s
    end
    lines.join("\n")
  end

  private

  # Determine the destination of the trip
  def determine_destination
    # Find the destination by looking at the last unique destination from all segments thats is not the base IATA
    destinations = @segments.map(&:arrival_airport).uniq
    destinations.reject { |destination| destination == @base_airport }.last
  end
end