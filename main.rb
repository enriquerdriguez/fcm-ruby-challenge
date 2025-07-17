# rubocop:disable all
require_relative 'lib/segment'
require_relative 'lib/trip'
require_relative 'lib/itinerary_processor'
require 'pry'

# frozen_string_literal: true

# Main application class that will wrap the whole app
class MainApp

  def self.run
    new.run
  end

  def run
    input_file = ARGV[0]
    base_airport = ENV['BASED']

    if input_file.nil?
      puts 'Warning: No input file provided'
      exit 1
    end

    begin
      processor = ItineraryProcessor.new(base_airport)
      trips = processor.process_file(input_file)
      processor.display_trips(trips)

    rescue ItineraryErrors::ItineraryError => e
      puts "Unexpected Error: #{e.message}"
      exit 1
    end


  end
end

# Run the whole app when the file is executed directly
MainApp.run if __FILE__ == $PROGRAM_NAME
