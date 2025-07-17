# Custom error classes for the itinerary application
module ItineraryErrors
  # Base error class for all itinerary-related errors
  class ItineraryError < StandardError; end

  # Error raised when a segment has invalid data
  class InvalidSegmentError < ItineraryError; end

  # Error raised when date/time parsing fails
  class DateTimeParseError < ItineraryError; end

  # Error raised when IATA code is invalid
  class InvalidIataCodeError < ItineraryError; end

  # Error raised when a trip is invalid
  class InvalidTripError < ItineraryError; end
end
