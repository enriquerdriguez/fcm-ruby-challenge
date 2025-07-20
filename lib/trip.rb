# frozen_string_literal: true

require_relative 'segment'

# Class that represents a trip, it contains a list of segments and a base airport
class Trip
  attr_reader :segments, :base_airport

  def initialize(segments:, base_airport:)
    @segments = segments
    @base_airport = base_airport
    @destination = determine_destination
  end

  # Method to validate the initial point segments, if there are no segments that start from the base IATA, raise an error
  def self.validate_initial_point_segments(segments)
    raise ItineraryErrors::InvalidTripError, "There are no segments that start from the base IATA #{@base_airport}" if segments.empty?
  end

  # Method to check if a segment is linked to the current location and time
  def self.next_linked_segment?(segment, current_location, current_time)
    return transport_segment_linked?(segment, current_location, current_time) if segment.transport?

    hotel_segment_linked?(segment, current_location, current_time)
  end

  # Method to group segments into trips
  # rubocop:disable all
  # Time Complexity: O(n^2) where n is the number of segments
  # - Initial sort of segments: O(n log n)
  # - For each initial segment (worst case n/2):
  #   - Inner while loop can process remaining segments (worst case n/2)
  #   - Finding next linked segment is O(n) operation
  # Space Complexity: O(n) for storing sorted segments and trips
  def self.group_segments(segments, base_airport)
    return [] if segments.empty?

    # Sort all segments chronologically by start time to process them in order
    sorted = Segment.sort_by_date(segments)

    # each trip should start with a transport segment leaving the base IATA
    initial_point_segments = sorted.select { |segment| segment.departure_airport == base_airport }
    validate_initial_point_segments(initial_point_segments)

    sorted -= initial_point_segments

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
        next_segment = sorted.find { |segment| next_linked_segment?(segment, current_location, current_time) }

        break unless next_segment

        # Add segment to trip and update current location/time
        current_trip_segments << next_segment
        sorted.delete(next_segment)

        current_location = next_segment.arrival_airport
        current_time = next_segment.transport? ? next_segment.arrival_time : next_segment.check_out_date.to_datetime
      end

      # Add completed trip to trips array
      trips << Trip.new(segments: current_trip_segments, base_airport: base_airport)
    end

    # Order trips by earliest date
    trips.sort_by(&:earliest_date)
  end
  # rubocop:enable all

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

  def self.transport_segment_linked?(segment, current_location, current_time)
    segment.departure_airport == current_location &&
      segment.departure_time >= current_time &&
      (segment.departure_time - current_time) <= 1.0
  end

  def self.hotel_segment_linked?(segment, current_location, current_time)
    segment.arrival_airport == current_location &&
      segment.check_in_date >= current_time.to_date &&
      (segment.check_in_date - current_time.to_date) <= 1.0
  end

  private

  # Determine the destination of the trip
  def determine_destination
    # Find the destination by looking at the last unique destination from all segments thats is not the base IATA
    destinations = @segments.map(&:arrival_airport).uniq
    destinations.reject { |destination| destination == @base_airport }.last
  end
end
