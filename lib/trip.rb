# frozen_string_literal: true

require 'set'
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
  def self.validate_initial_point_segments(segments, base_airport)
    raise ItineraryErrors::InvalidTripError, "There are no segments that start from the base IATA #{base_airport}" if segments.empty?
  end

  # Method to group segments into trips using hash maps
  def self.group_segments(segments, base_airport)
    return [] if segments.empty?

    # Sort all segments chronologically by start time
    sorted_segments = Segment.sort_by_date(segments)

    # Build hash maps for faster searches
    segments_by_departure = build_departure_hash_map(sorted_segments)
    segments_by_arrival = build_arrival_hash_map(sorted_segments)

    # Find initial segments that start from base airport
    initial_segments = segments_by_departure[base_airport] || []
    validate_initial_point_segments(initial_segments, base_airport)

    # Build trips from initial segments
    build_trips_from_initial_segments(initial_segments, segments_by_departure, segments_by_arrival, base_airport)
  end

  # Build trips from initial segments
  def self.build_trips_from_initial_segments(initial_segments, segments_by_departure, segments_by_arrival, base_airport)
    trips = []
    used_segments = Set.new

    # Process each initial segment
    initial_segments.each do |initial_segment|
      next if used_segments.include?(initial_segment)

      trip_segments = build_trip_from_segment(initial_segment, segments_by_departure, segments_by_arrival, used_segments, base_airport)

      trips << Trip.new(segments: trip_segments, base_airport: base_airport)
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

  # Method to check if a transport segment is linked to the current location and time
  def self.transport_segment_linked?(segment, current_location, current_time)
    segment.departure_airport == current_location &&
      segment.departure_time >= current_time &&
      (segment.departure_time - current_time) <= 1.0
  end

  # Method to check if a hotel segment is linked to the current location and time
  def self.hotel_segment_linked?(segment, current_location, current_time)
    segment.arrival_airport == current_location &&
      segment.check_in_date >= current_time.to_date &&
      (segment.check_in_date - current_time.to_date) <= 1.0
  end

  private

  # Build a hash map of segments indexed by departure airport
  def self.build_departure_hash_map(segments)
    segments.group_by(&:departure_airport)
  end

  # Build a hash map of segments indexed by arrival airport
  def self.build_arrival_hash_map(segments)
    segments.group_by(&:arrival_airport)
  end

  # Build a complete trip starting from a given segment
  def self.build_trip_from_segment(initial_segment, segments_by_departure, segments_by_arrival, used_segments, base_airport)
    trip_segments = [initial_segment]
    used_segments.add(initial_segment)

    # Set current segment date to find next linked segment
    current_segment = initial_segment
    current_location = current_segment.arrival_airport
    current_time = get_segment_end_time(current_segment)

    # Continue building trip until we return to base or can't find next segment
    while current_location != base_airport
      next_segment = find_next_linked_segment(current_location, current_time, segments_by_departure,
                                              segments_by_arrival, used_segments)

      break unless next_segment

      trip_segments << next_segment
      used_segments.add(next_segment)

      current_location = next_segment.arrival_airport
      current_time = get_segment_end_time(next_segment)
    end

    trip_segments
  end

  # Get the end time of a segment (arrival time for transport, check out for hotel)
  def self.get_segment_end_time(segment)
    segment.transport? ? segment.arrival_time : segment.check_out_date.to_datetime
  end

  # Method to find the next linked segment using hash maps
  def self.find_next_linked_segment(current_location, current_time, segments_by_departure, segments_by_arrival, used_segments)
    # First try to find transport segments departing from current location
    next_transport = find_next_transport_segment(current_location, current_time, segments_by_departure, used_segments)
    return next_transport if next_transport

    # If no transport segment found, look for hotel segments at current location
    find_next_hotel_segment(current_location, current_time, segments_by_arrival, used_segments)
  end

  # Find the next transport segment from current location
  def self.find_next_transport_segment(current_location, current_time, segments_by_departure, used_segments)
    transport_candidates = segments_by_departure[current_location]&.select do |segment|
      segment.transport? && !used_segments.include?(segment)
    end || []

    transport_candidates.find do |segment|
      transport_segment_linked?(segment, current_location, current_time)
    end
  end

  # Find the next hotel segment at current location
  def self.find_next_hotel_segment(current_location, current_time, segments_by_arrival, used_segments)
    hotel_candidates = segments_by_arrival[current_location]&.select do |segment|
      segment.hotel? && !used_segments.include?(segment)
    end || []

    hotel_candidates.find do |segment|
      hotel_segment_linked?(segment, current_location, current_time)
    end
  end

  private_class_method :build_departure_hash_map, :build_arrival_hash_map, :build_trip_from_segment,
                       :get_segment_end_time, :find_next_linked_segment,
                       :find_next_transport_segment, :find_next_hotel_segment, :build_trips_from_initial_segments

  # Determine the destination of the trip
  def determine_destination
    # Find the destination by looking at the last unique destination from all segments thats is not the base IATA
    destinations = @segments.map(&:arrival_airport).uniq
    destinations.reject { |destination| destination == @base_airport }.last
  end
end
