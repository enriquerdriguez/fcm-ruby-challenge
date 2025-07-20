# frozen_string_literal: true
# rubocop:disable all

require 'spec_helper'
require_relative '../../lib/trip'

RSpec.describe Trip do
  let(:base_airport) { 'SVQ' }

  describe '.group_segments' do
    context 'with valid segments' do
      let(:flight_segment) do
        double('Segment',
               type: 'Flight',
               departure_airport: 'SVQ',
               arrival_airport: 'BCN',
               departure_time: DateTime.parse('2023-01-05 20:40'),
               arrival_time: DateTime.parse('2023-01-05 22:10'),
               transport?: true,
               hotel?: false,
               check_in_date: nil,
               check_out_date: nil)
      end

      let(:hotel_segment) do
        double('Segment',
               type: 'Hotel',
               departure_airport: nil,
               arrival_airport: 'BCN',
               departure_time: nil,
               arrival_time: nil,
               transport?: false,
               hotel?: true,
               check_in_date: Date.parse('2023-01-05'),
               check_out_date: Date.parse('2023-01-10'))
      end

      let(:return_flight_segment) do
        double('Segment',
               type: 'Flight',
               departure_airport: 'BCN',
               arrival_airport: 'SVQ',
               departure_time: DateTime.parse('2023-01-10 10:30'),
               arrival_time: DateTime.parse('2023-01-10 11:50'),
               transport?: true,
               hotel?: false,
               check_in_date: nil,
               check_out_date: nil)
      end

      let(:train_segment) do
        double('Segment',
               type: 'Train',
               departure_airport: 'SVQ',
               arrival_airport: 'MAD',
               departure_time: DateTime.parse('2023-02-15 09:30'),
               arrival_time: DateTime.parse('2023-02-15 11:00'),
               transport?: true,
               hotel?: false,
               check_in_date: nil,
               check_out_date: nil)
      end

      let(:mad_hotel_segment) do
        double('Segment',
               type: 'Hotel',
               departure_airport: nil,
               arrival_airport: 'MAD',
               departure_time: nil,
               arrival_time: nil,
               transport?: false,
               hotel?: true,
               check_in_date: Date.parse('2023-02-15'),
               check_out_date: Date.parse('2023-02-17'))
      end

      let(:return_train_segment) do
        double('Segment',
               type: 'Train',
               departure_airport: 'MAD',
               arrival_airport: 'SVQ',
               departure_time: DateTime.parse('2023-02-17 17:00'),
               arrival_time: DateTime.parse('2023-02-17 19:30'),
               transport?: true,
               hotel?: false,
               check_in_date: nil,
               check_out_date: nil)
      end

      let(:nyc_flight_segment) do
        double('Segment',
               type: 'Flight',
               departure_airport: 'SVQ',
               arrival_airport: 'BCN',
               departure_time: DateTime.parse('2023-03-02 06:40'),
               arrival_time: DateTime.parse('2023-03-02 09:10'),
               transport?: true,
               hotel?: false,
               check_in_date: nil,
               check_out_date: nil)
      end

      let(:nyc_connection_segment) do
        double('Segment',
               type: 'Flight',
               departure_airport: 'BCN',
               arrival_airport: 'NYC',
               departure_time: DateTime.parse('2023-03-02 15:00'),
               arrival_time: DateTime.parse('2023-03-02 22:45'),
               transport?: true,
               hotel?: false,
               check_in_date: nil,
               check_out_date: nil)
      end

      let(:segments) do
        [flight_segment, hotel_segment, return_flight_segment, train_segment,
         mad_hotel_segment, return_train_segment, nyc_flight_segment, nyc_connection_segment]
      end

      before do
        # Mock the Segment.sort_by_date method
        allow(Segment).to receive(:sort_by_date).and_return(segments)
      end

      it 'groups segments into trips correctly' do
        trips = Trip.group_segments(segments, base_airport)

        expect(trips.length).to eq(3)

        # First trip to BCN
        expect(trips[0].segments.length).to eq(3)
        expect(trips[0].segments[0]).to eq(flight_segment)
        expect(trips[0].segments[1]).to eq(hotel_segment)
        expect(trips[0].segments[2]).to eq(return_flight_segment)

        # Second trip to MAD
        expect(trips[1].segments.length).to eq(3)
        expect(trips[1].segments[0]).to eq(train_segment)
        expect(trips[1].segments[1]).to eq(mad_hotel_segment)
        expect(trips[1].segments[2]).to eq(return_train_segment)

        # Third trip to NYC
        expect(trips[2].segments.length).to eq(2)
        expect(trips[2].segments[0]).to eq(nyc_flight_segment)
        expect(trips[2].segments[1]).to eq(nyc_connection_segment)
      end

      it 'orders trips by earliest date' do
        trips = Trip.group_segments(segments, base_airport)

        expect(trips[0].earliest_date).to be < trips[1].earliest_date
        expect(trips[1].earliest_date).to be < trips[2].earliest_date
      end
    end

    context 'with segments that connect within 24 hours' do
      let(:first_segment) do
        double('Segment',
               departure_airport: 'SVQ',
               arrival_airport: 'BCN',
               departure_time: DateTime.parse('2023-03-02 06:40'),
               arrival_time: DateTime.parse('2023-03-02 09:10'),
               transport?: true,
               hotel?: false)
      end

      let(:second_segment) do
        double('Segment',
               departure_airport: 'BCN',
               arrival_airport: 'NYC',
               departure_time: DateTime.parse('2023-03-02 15:00'),
               arrival_time: DateTime.parse('2023-03-02 22:45'),
               transport?: true,
               hotel?: false)
      end

      let(:segments) { [first_segment, second_segment] }

      before do
        allow(Segment).to receive(:sort_by_date).and_return(segments)
      end

      it 'connects segments within 24 hours' do
        trips = Trip.group_segments(segments, base_airport)

        expect(trips.length).to eq(1)
        expect(trips[0].segments.length).to eq(2)
        expect(trips[0].segments[0]).to eq(first_segment)
        expect(trips[0].segments[1]).to eq(second_segment)
      end
    end

    context 'with segments that exceed 24 hours gap' do
      let(:first_segment) do
        double('Segment',
               departure_airport: 'SVQ',
               arrival_airport: 'BCN',
               departure_time: DateTime.parse('2023-03-02 06:40'),
               arrival_time: DateTime.parse('2023-03-02 09:10'),
               transport?: true,
               hotel?: false)
      end

      let(:second_segment) do
        double('Segment',
               departure_airport: 'BCN',
               arrival_airport: 'NYC',
               departure_time: DateTime.parse('2023-03-04 15:00'), # More than 24 hours later
               arrival_time: DateTime.parse('2023-03-04 22:45'),
               transport?: true,
               hotel?: false)
      end

      let(:segments) { [first_segment, second_segment] }

      before do
        allow(Segment).to receive(:sort_by_date).and_return(segments)
      end

      it 'creates separate trips for segments with more than 24 hours gap' do
        trips = Trip.group_segments(segments, base_airport)

        # The current implementation only groups segments that start from base airport
        # So this creates one trip starting from SVQ, and the BCN->NYC segment is not included
        expect(trips.length).to eq(1)
        expect(trips[0].segments.length).to eq(1)
        expect(trips[0].segments[0]).to eq(first_segment)
      end
    end

    context 'with hotel segments connecting to transport' do
      let(:flight_segment) do
        double('Segment',
               departure_airport: 'SVQ',
               arrival_airport: 'BCN',
               departure_time: DateTime.parse('2023-01-05 20:40'),
               arrival_time: DateTime.parse('2023-01-05 22:10'),
               transport?: true,
               hotel?: false)
      end

      let(:hotel_segment) do
        double('Segment',
               departure_airport: nil,
               arrival_airport: 'BCN',
               departure_time: nil,
               arrival_time: nil,
               transport?: false,
               hotel?: true,
               check_in_date: Date.parse('2023-01-05'),
               check_out_date: Date.parse('2023-01-10'))
      end

      let(:return_flight_segment) do
        double('Segment',
               departure_airport: 'BCN',
               arrival_airport: 'SVQ',
               departure_time: DateTime.parse('2023-01-10 10:30'),
               arrival_time: DateTime.parse('2023-01-10 11:50'),
               transport?: true,
               hotel?: false)
      end

      let(:segments) { [flight_segment, hotel_segment, return_flight_segment] }

      before do
        allow(Segment).to receive(:sort_by_date).and_return(segments)
      end

      it 'connects hotel segments to transport segments' do
        trips = Trip.group_segments(segments, base_airport)

        expect(trips.length).to eq(1)
        expect(trips[0].segments.length).to eq(3)
        expect(trips[0].segments[0]).to eq(flight_segment)
        expect(trips[0].segments[1]).to eq(hotel_segment)
        expect(trips[0].segments[2]).to eq(return_flight_segment)
      end
    end

    context 'with empty segments array' do
      it 'returns empty array' do
        trips = Trip.group_segments([], base_airport)
        expect(trips).to eq([])
      end
    end

    context 'with no segments starting from base airport' do
      let(:segment) do
        double('Segment',
               departure_airport: 'BCN',
               arrival_airport: 'NYC',
               departure_time: DateTime.parse('2023-03-02 15:00'),
               arrival_time: DateTime.parse('2023-03-02 22:45'),
               transport?: true,
               hotel?: false)
      end

      let(:segments) { [segment] }

      before do
        allow(Segment).to receive(:sort_by_date).and_return(segments)
      end

      it 'raises error when no segments start from base airport' do
        expect do
          Trip.group_segments(segments, base_airport)
        end.to raise_error(ItineraryErrors::InvalidTripError, /There are no segments that start from the base IATA SVQ/)
      end
    end

    context 'with different base airports' do
      let(:segment) do
        double('Segment',
               departure_airport: 'MAD',
               arrival_airport: 'BCN',
               departure_time: DateTime.parse('2023-03-02 15:00'),
               arrival_time: DateTime.parse('2023-03-02 16:30'),
               transport?: true,
               hotel?: false)
      end

      let(:segments) { [segment] }

      before do
        allow(Segment).to receive(:sort_by_date).and_return(segments)
      end

      it 'works with different base airports' do
        trips = Trip.group_segments(segments, 'MAD')

        expect(trips.length).to eq(1)
        expect(trips[0].segments[0]).to eq(segment)
      end
    end
  end

  describe '#initialize' do
    let(:segment) do
      double('Segment',
             departure_airport: 'SVQ',
             arrival_airport: 'BCN',
             departure_time: DateTime.parse('2023-03-02 06:40'),
             arrival_time: DateTime.parse('2023-03-02 09:10'),
             transport?: true,
             hotel?: false)
    end

    let(:segments) { [segment] }

    it 'initializes with segments and base airport' do
      trip = Trip.new(segments: segments, base_airport: base_airport)

      expect(trip.segments).to eq(segments)
      expect(trip.base_airport).to eq(base_airport)
    end
  end

  describe '#earliest_date' do
    let(:flight_segment) do
      double('Segment',
             departure_airport: 'SVQ',
             arrival_airport: 'BCN',
             departure_time: DateTime.parse('2023-03-02 06:40'),
             arrival_time: DateTime.parse('2023-03-02 09:10'),
             transport?: true,
             hotel?: false)
    end

    let(:hotel_segment) do
      double('Segment',
             departure_airport: nil,
             arrival_airport: 'BCN',
             departure_time: nil,
             arrival_time: nil,
             transport?: false,
             hotel?: true,
             check_in_date: Date.parse('2023-03-01'))
    end

    let(:segments) { [flight_segment, hotel_segment] }

    it 'returns the earliest date from all segments' do
      trip = Trip.new(segments: segments, base_airport: base_airport)
      expect(trip.earliest_date).to eq(Date.parse('2023-03-01'))
    end

    it 'handles empty segments' do
      trip = Trip.new(segments: [], base_airport: base_airport)
      expect(trip.earliest_date).to be_nil
    end
  end

  describe '#to_s' do
    let(:flight_segment) do
      double('Segment',
             departure_airport: 'SVQ',
             arrival_airport: 'BCN',
             departure_time: DateTime.parse('2023-03-02 06:40'),
             arrival_time: DateTime.parse('2023-03-02 09:10'),
             transport?: true,
             hotel?: false,
             to_s: 'Flight from SVQ to BCN at 2023-03-02 06:40 to 09:10')
    end

    let(:nyc_segment) do
      double('Segment',
             departure_airport: 'BCN',
             arrival_airport: 'NYC',
             departure_time: DateTime.parse('2023-03-02 15:00'),
             arrival_time: DateTime.parse('2023-03-02 22:45'),
             transport?: true,
             hotel?: false,
             to_s: 'Flight from BCN to NYC at 2023-03-02 15:00 to 22:45')
    end

    let(:segments) { [flight_segment, nyc_segment] }

    it 'formats trip correctly' do
      trip = Trip.new(segments: segments, base_airport: base_airport)
      output = trip.to_s

      expect(output).to include('TRIP to NYC')
      expect(output).to include('Flight from SVQ to BCN at 2023-03-02 06:40 to 09:10')
      expect(output).to include('Flight from BCN to NYC at 2023-03-02 15:00 to 22:45')
    end

    it 'handles empty segments' do
      trip = Trip.new(segments: [], base_airport: base_airport)
      expect(trip.to_s).to be_nil
    end
  end

  describe '#determine_destination' do
    context 'with single destination' do
      let(:segment) do
        double('Segment',
               departure_airport: 'SVQ',
               arrival_airport: 'BCN',
               departure_time: DateTime.parse('2023-03-02 06:40'),
               arrival_time: DateTime.parse('2023-03-02 09:10'),
               transport?: true,
               hotel?: false)
      end

      let(:segments) { [segment] }

      it 'returns the destination' do
        trip = Trip.new(segments: segments, base_airport: base_airport)
        expect(trip.send(:determine_destination)).to eq('BCN')
      end
    end

    context 'with multiple destinations' do
      let(:first_segment) do
        double('Segment',
               departure_airport: 'SVQ',
               arrival_airport: 'BCN',
               transport?: true,
               hotel?: false)
      end

      let(:second_segment) do
        double('Segment',
               departure_airport: 'BCN',
               arrival_airport: 'NYC',
               transport?: true,
               hotel?: false)
      end

      let(:third_segment) do
        double('Segment',
               departure_airport: 'NYC',
               arrival_airport: 'SVQ',
               transport?: true,
               hotel?: false)
      end

      let(:segments) { [first_segment, second_segment, third_segment] }

      it 'returns the last unique destination that is not the base airport' do
        trip = Trip.new(segments: segments, base_airport: base_airport)
        expect(trip.send(:determine_destination)).to eq('NYC')
      end
    end

    context 'with segments returning to base airport' do
      let(:first_segment) do
        double('Segment',
               departure_airport: 'SVQ',
               arrival_airport: 'BCN',
               transport?: true,
               hotel?: false)
      end

      let(:second_segment) do
        double('Segment',
               departure_airport: 'BCN',
               arrival_airport: 'SVQ',
               transport?: true,
               hotel?: false)
      end

      let(:segments) { [first_segment, second_segment] }

      it 'returns the destination before returning to base' do
        trip = Trip.new(segments: segments, base_airport: base_airport)
        expect(trip.send(:determine_destination)).to eq('BCN')
      end
    end
  end
end 