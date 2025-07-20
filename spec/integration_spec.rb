# frozen_string_literal: true

require 'spec_helper'
require_relative '../lib/itinerary_processor'

RSpec.describe 'Integration Tests' do
  describe 'with valid input file' do
    let(:input_file) { 'input.txt' }

    it 'processes the main input file correctly' do
      processor = ItineraryProcessor.new('SVQ')
      trips = processor.process_file(input_file)

      expect(trips.length).to eq(3)

      # First trip to BCN
      expect(trips[0].to_s).to include('TRIP to BCN')
      expect(trips[0].to_s).to include('Flight from SVQ to BCN')
      expect(trips[0].to_s).to include('Hotel at BCN')
      expect(trips[0].to_s).to include('Flight from BCN to SVQ')

      # Second trip to MAD
      expect(trips[1].to_s).to include('TRIP to MAD')
      expect(trips[1].to_s).to include('Train from SVQ to MAD')
      expect(trips[1].to_s).to include('Hotel at MAD')
      expect(trips[1].to_s).to include('Train from MAD to SVQ')

      # Third trip to NYC
      expect(trips[2].to_s).to include('TRIP to NYC')
      expect(trips[2].to_s).to include('Flight from SVQ to BCN')
      expect(trips[2].to_s).to include('Flight from BCN to NYC')
    end
  end

  describe 'with different base airports' do
    it 'works with BCN as base airport' do
      processor = ItineraryProcessor.new('BCN')
      trips = processor.process_file('input.txt')

      expect(trips.length).to eq(2)
      expect(trips[0].to_s).to include('TRIP to SVQ')
      expect(trips[1].to_s).to include('TRIP to NYC')
    end

    it 'works with MAD as base airport' do
      processor = ItineraryProcessor.new('MAD')
      trips = processor.process_file('input.txt')

      expect(trips.length).to eq(1)
      expect(trips[0].to_s).to include('TRIP to SVQ')
    end

    it 'raises error with NYC as base airport' do
      processor = ItineraryProcessor.new('NYC')
      expect do
        processor.process_file('input.txt')
      end.to raise_error(ItineraryErrors::InvalidTripError,
                         /There are no segments that start from the base IATA NYC/)
    end
  end

  describe 'with edge case input files' do
    it 'handles wrong segment type error' do
      processor = ItineraryProcessor.new('SVQ')
      expect do
        processor.process_file('inputs/input_wrong_segment_type.txt')
      end.to raise_error(ItineraryErrors::InvalidSegmentError,
                         /Invalid segment type: AIRBNB/)
    end

    it 'handles wrong IATA code error' do
      processor = ItineraryProcessor.new('SVQ')
      expect do
        processor.process_file('inputs/input_wrong_iata.txt')
      end.to raise_error(ItineraryErrors::InvalidSegmentError,
                         /Invalid departure_airport: SQ/)
    end

    it 'handles wrong date format error' do
      processor = ItineraryProcessor.new('SVQ')
      expect do
        processor.process_file('inputs/input_wrong_date_format.txt')
      end.to raise_error(ItineraryErrors::DateTimeParseError,
                         /Invalid date format for nil/)
    end

    it 'handles wrong dates error' do
      processor = ItineraryProcessor.new('SVQ')
      expect do
        processor.process_file('inputs/input_wrong_dates.txt')
      end.to raise_error(ItineraryErrors::DateTimeParseError,
                         /Invalid datetime format/)
    end

    it 'handles wrong date inside out error' do
      processor = ItineraryProcessor.new('SVQ')
      expect do
        processor.process_file('inputs/input_wrong_date_inside_out.txt')
      end.to raise_error(
        ItineraryErrors::InvalidSegmentError, /Check-in date must be before check-out date/
      )
    end
  end
end
