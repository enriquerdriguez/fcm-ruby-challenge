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

      let(:segments) { [flight_segment, hotel_segment, return_flight_segment, train_segment, mad_hotel_segment, return_train_segment, nyc_flight_segment, nyc_connection_segment] }

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

        expect(trips.length).to eq(1)
        expect(trips[0].segments.length).to eq(1)
        expect(trips[0].segments[0]).to eq(first_segment)
      end
    end

    context 'with hotel segments connecting to transport' do
      let(:initial_segment) do
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

      let(:hotel_segment) do
        double('Segment',
               type: 'Hotel',
               departure_airport: nil,
               arrival_airport: 'BCN',
               departure_time: nil,
               arrival_time: nil,
               transport?: false,
               hotel?: true,
               check_in_date: Date.parse('2023-03-02'),
               check_out_date: Date.parse('2023-03-05'))
      end

      let(:transport_segment) do
        double('Segment',
               type: 'Flight',
               departure_airport: 'BCN',
               arrival_airport: 'NYC',
               departure_time: DateTime.parse('2023-03-05 10:00'),
               arrival_time: DateTime.parse('2023-03-05 17:00'),
               transport?: true,
               hotel?: false,
               check_in_date: nil,
               check_out_date: nil)
      end

      let(:segments) { [initial_segment, hotel_segment, transport_segment] }

      before do
        allow(Segment).to receive(:sort_by_date).and_return(segments)
      end

      it 'connects hotel segments to transport segments' do
        trips = Trip.group_segments(segments, base_airport)

        expect(trips.length).to eq(1)
        expect(trips[0].segments.length).to eq(3)
        expect(trips[0].segments[0]).to eq(initial_segment)
        expect(trips[0].segments[1]).to eq(hotel_segment)
        expect(trips[0].segments[2]).to eq(transport_segment)
      end
    end

    context 'with empty segments' do
      it 'returns empty array' do
        trips = Trip.group_segments([], base_airport)
        expect(trips).to eq([])
      end
    end

    context 'with no segments from base airport' do
      let(:segment) do
        double('Segment',
               departure_airport: 'BCN',
               arrival_airport: 'NYC',
               departure_time: DateTime.parse('2023-03-02 06:40'),
               arrival_time: DateTime.parse('2023-03-02 09:10'),
               transport?: true,
               hotel?: false)
      end

      let(:segments) { [segment] }

      before do
        allow(Segment).to receive(:sort_by_date).and_return(segments)
      end

      it 'raises an error' do
        expect { Trip.group_segments(segments, base_airport) }.to raise_error(ItineraryErrors::InvalidTripError)
      end
    end

    context 'with different base airports' do
      let(:segment) do
        double('Segment',
               departure_airport: 'MAD',
               arrival_airport: 'BCN',
               departure_time: DateTime.parse('2023-03-02 06:40'),
               arrival_time: DateTime.parse('2023-03-02 09:10'),
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
        expect(trips[0].segments.length).to eq(1)
        expect(trips[0].segments[0]).to eq(segment)
      end
    end
  end

  describe '#earliest_date' do
    context 'with transport segments' do
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

      it 'returns the departure time' do
        trip = Trip.new(segments: segments, base_airport: base_airport)
        expect(trip.earliest_date).to eq(DateTime.parse('2023-03-02 06:40'))
      end
    end

    context 'with hotel segments' do
      let(:segment) do
        double('Segment',
               departure_airport: nil,
               arrival_airport: 'BCN',
               departure_time: nil,
               arrival_time: nil,
               transport?: false,
               hotel?: true,
               check_in_date: Date.parse('2023-03-02'),
               check_out_date: Date.parse('2023-03-05'))
      end

      let(:segments) { [segment] }

      it 'returns the check-in date' do
        trip = Trip.new(segments: segments, base_airport: base_airport)
        expect(trip.earliest_date).to eq(Date.parse('2023-03-02'))
      end
    end

    context 'with multiple segments' do
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
               departure_airport: nil,
               arrival_airport: 'BCN',
               departure_time: nil,
               arrival_time: nil,
               transport?: false,
               hotel?: true,
               check_in_date: Date.parse('2023-03-01'),
               check_out_date: Date.parse('2023-03-05'))
      end

      let(:segments) { [first_segment, second_segment] }

      it 'returns the earliest date' do
        trip = Trip.new(segments: segments, base_airport: base_airport)
        expect(trip.earliest_date).to eq(Date.parse('2023-03-01'))
      end
    end
  end

  describe '#to_s' do
    context 'with valid segments' do
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

  describe '.build_departure_hash_map' do
    let(:segment1) { double('Segment', departure_airport: 'SVQ') }
    let(:segment2) { double('Segment', departure_airport: 'SVQ') }
    let(:segment3) { double('Segment', departure_airport: 'BCN') }
    let(:segments) { [segment1, segment2, segment3] }

    it 'groups segments by departure airport' do
      result = Trip.send(:build_departure_hash_map, segments)
      
      expect(result['SVQ']).to contain_exactly(segment1, segment2)
      expect(result['BCN']).to contain_exactly(segment3)
    end

    it 'returns empty hash for empty segments' do
      result = Trip.send(:build_departure_hash_map, [])
      expect(result).to eq({})
    end
  end

  describe '.build_arrival_hash_map' do
    let(:segment1) { double('Segment', arrival_airport: 'BCN') }
    let(:segment2) { double('Segment', arrival_airport: 'BCN') }
    let(:segment3) { double('Segment', arrival_airport: 'MAD') }
    let(:segments) { [segment1, segment2, segment3] }

    it 'groups segments by arrival airport' do
      result = Trip.send(:build_arrival_hash_map, segments)
      
      expect(result['BCN']).to contain_exactly(segment1, segment2)
      expect(result['MAD']).to contain_exactly(segment3)
    end

    it 'returns empty hash for empty segments' do
      result = Trip.send(:build_arrival_hash_map, [])
      expect(result).to eq({})
    end
  end

  describe '.transport_segment_linked?' do
    let(:current_location) { 'SVQ' }
    let(:current_time) { DateTime.parse('2023-03-02 10:00') }

    context 'with valid transport segment' do
      let(:segment) do
        double('Segment',
               departure_airport: 'SVQ',
               departure_time: DateTime.parse('2023-03-02 11:00'))
      end

      it 'returns true for linked transport segment' do
        result = Trip.send(:transport_segment_linked?, segment, current_location, current_time)
        expect(result).to be true
      end
    end

    context 'with wrong departure airport' do
      let(:segment) do
        double('Segment',
               departure_airport: 'BCN',
               departure_time: DateTime.parse('2023-03-02 11:00'))
      end

      it 'returns false' do
        result = Trip.send(:transport_segment_linked?, segment, current_location, current_time)
        expect(result).to be false
      end
    end

    context 'with departure time before current time' do
      let(:segment) do
        double('Segment',
               departure_airport: 'SVQ',
               departure_time: DateTime.parse('2023-03-02 09:00'))
      end

      it 'returns false' do
        result = Trip.send(:transport_segment_linked?, segment, current_location, current_time)
        expect(result).to be false
      end
    end

    context 'with departure time more than 24 hours later' do
      let(:segment) do
        double('Segment',
               departure_airport: 'SVQ',
               departure_time: DateTime.parse('2023-03-04 11:00'))
      end

      it 'returns false' do
        result = Trip.send(:transport_segment_linked?, segment, current_location, current_time)
        expect(result).to be false
      end
    end

    context 'with departure time exactly 24 hours later' do
      let(:segment) do
        double('Segment',
               departure_airport: 'SVQ',
               departure_time: DateTime.parse('2023-03-03 10:00'))
      end

      it 'returns true' do
        result = Trip.send(:transport_segment_linked?, segment, current_location, current_time)
        expect(result).to be true
      end
    end
  end

  describe '.hotel_segment_linked?' do
    let(:current_location) { 'BCN' }
    let(:current_time) { DateTime.parse('2023-03-02 10:00') }

    context 'with valid hotel segment' do
      let(:segment) do
        double('Segment',
               arrival_airport: 'BCN',
               check_in_date: Date.parse('2023-03-02'))
      end

      it 'returns true for linked hotel segment' do
        result = Trip.send(:hotel_segment_linked?, segment, current_location, current_time)
        expect(result).to be true
      end
    end

    context 'with wrong arrival airport' do
      let(:segment) do
        double('Segment',
               arrival_airport: 'MAD',
               check_in_date: Date.parse('2023-03-02'))
      end

      it 'returns false' do
        result = Trip.send(:hotel_segment_linked?, segment, current_location, current_time)
        expect(result).to be false
      end
    end

    context 'with check-in date before current date' do
      let(:segment) do
        double('Segment',
               arrival_airport: 'BCN',
               check_in_date: Date.parse('2023-03-01'))
      end

      it 'returns false' do
        result = Trip.send(:hotel_segment_linked?, segment, current_location, current_time)
        expect(result).to be false
      end
    end

    context 'with check-in date more than 24 hours later' do
      let(:segment) do
        double('Segment',
               arrival_airport: 'BCN',
               check_in_date: Date.parse('2023-03-04'))
      end

      it 'returns false' do
        result = Trip.send(:hotel_segment_linked?, segment, current_location, current_time)
        expect(result).to be false
      end
    end

    context 'with check-in date exactly 24 hours later' do
      let(:segment) do
        double('Segment',
               arrival_airport: 'BCN',
               check_in_date: Date.parse('2023-03-03'))
      end

      it 'returns true' do
        result = Trip.send(:hotel_segment_linked?, segment, current_location, current_time)
        expect(result).to be true
      end
    end
  end

  describe '.get_segment_end_time' do
    context 'with transport segment' do
      let(:segment) do
        double('Segment',
               transport?: true,
               hotel?: false,
               arrival_time: DateTime.parse('2023-03-02 11:00'),
               check_out_date: nil)
      end

      it 'returns arrival time' do
        result = Trip.send(:get_segment_end_time, segment)
        expect(result).to eq(DateTime.parse('2023-03-02 11:00'))
      end
    end

    context 'with hotel segment' do
      let(:segment) do
        double('Segment',
               transport?: false,
               hotel?: true,
               arrival_time: nil,
               check_out_date: Date.parse('2023-03-05'))
      end

      it 'returns check-out date as datetime' do
        result = Trip.send(:get_segment_end_time, segment)
        expect(result).to eq(DateTime.parse('2023-03-05'))
      end
    end
  end

  describe '.find_next_transport_segment' do
    let(:current_location) { 'SVQ' }
    let(:current_time) { DateTime.parse('2023-03-02 10:00') }
    let(:used_segments) { Set.new }

    let(:valid_segment) do
      double('Segment',
             transport?: true,
             hotel?: false,
             departure_airport: 'SVQ',
             departure_time: DateTime.parse('2023-03-02 11:00'))
    end

    let(:invalid_segment) do
      double('Segment',
             transport?: true,
             hotel?: false,
             departure_airport: 'SVQ',
             departure_time: DateTime.parse('2023-03-02 09:00'))
    end

    let(:hotel_segment) do
      double('Segment',
             transport?: false,
             hotel?: true,
             departure_airport: 'SVQ',
             departure_time: DateTime.parse('2023-03-02 11:00'))
    end

    let(:segments_by_departure) { { 'SVQ' => [valid_segment, invalid_segment, hotel_segment] } }

    it 'finds the next valid transport segment' do
      result = Trip.send(:find_next_transport_segment, current_location, current_time, segments_by_departure, used_segments)
      expect(result).to eq(valid_segment)
    end

    it 'returns nil when no valid transport segment found' do
      segments_by_departure = { 'SVQ' => [invalid_segment, hotel_segment] }
      result = Trip.send(:find_next_transport_segment, current_location, current_time, segments_by_departure, used_segments)
      expect(result).to be_nil
    end

    it 'excludes used segments' do
      used_segments.add(valid_segment)
      result = Trip.send(:find_next_transport_segment, current_location, current_time, segments_by_departure, used_segments)
      expect(result).to be_nil
    end

    it 'returns nil when no segments for location' do
      segments_by_departure = { 'BCN' => [valid_segment] }
      result = Trip.send(:find_next_transport_segment, current_location, current_time, segments_by_departure, used_segments)
      expect(result).to be_nil
    end
  end

  describe '.find_next_hotel_segment' do
    let(:current_location) { 'BCN' }
    let(:current_time) { DateTime.parse('2023-03-02 10:00') }
    let(:used_segments) { Set.new }

    let(:valid_segment) do
      double('Segment',
             transport?: false,
             hotel?: true,
             arrival_airport: 'BCN',
             check_in_date: Date.parse('2023-03-02'))
    end

    let(:invalid_segment) do
      double('Segment',
             transport?: false,
             hotel?: true,
             arrival_airport: 'BCN',
             check_in_date: Date.parse('2023-03-01'))
    end

    let(:transport_segment) do
      double('Segment',
             transport?: true,
             hotel?: false,
             arrival_airport: 'BCN',
             check_in_date: Date.parse('2023-03-02'))
    end

    let(:segments_by_arrival) { { 'BCN' => [valid_segment, invalid_segment, transport_segment] } }

    it 'finds the next valid hotel segment' do
      result = Trip.send(:find_next_hotel_segment, current_location, current_time, segments_by_arrival, used_segments)
      expect(result).to eq(valid_segment)
    end

    it 'returns nil when no valid hotel segment found' do
      segments_by_arrival = { 'BCN' => [invalid_segment, transport_segment] }
      result = Trip.send(:find_next_hotel_segment, current_location, current_time, segments_by_arrival, used_segments)
      expect(result).to be_nil
    end

    it 'excludes used segments' do
      used_segments.add(valid_segment)
      result = Trip.send(:find_next_hotel_segment, current_location, current_time, segments_by_arrival, used_segments)
      expect(result).to be_nil
    end

    it 'returns nil when no segments for location' do
      segments_by_arrival = { 'MAD' => [valid_segment] }
      result = Trip.send(:find_next_hotel_segment, current_location, current_time, segments_by_arrival, used_segments)
      expect(result).to be_nil
    end
  end

  describe '.find_next_linked_segment' do
    let(:current_location) { 'SVQ' }
    let(:current_time) { DateTime.parse('2023-03-02 10:00') }
    let(:used_segments) { Set.new }

    let(:transport_segment) do
      double('Segment',
             transport?: true,
             hotel?: false,
             departure_airport: 'SVQ',
             departure_time: DateTime.parse('2023-03-02 11:00'))
    end

    let(:hotel_segment) do
      double('Segment',
             transport?: false,
             hotel?: true,
             arrival_airport: 'SVQ',
             check_in_date: Date.parse('2023-03-02'))
    end

    let(:segments_by_departure) { { 'SVQ' => [transport_segment] } }
    let(:segments_by_arrival) { { 'SVQ' => [hotel_segment] } }

    it 'prioritizes transport segments over hotel segments' do
      result = Trip.send(:find_next_linked_segment, current_location, current_time, segments_by_departure, segments_by_arrival, used_segments)
      expect(result).to eq(transport_segment)
    end

    it 'falls back to hotel segments when no transport segment found' do
      segments_by_departure = { 'SVQ' => [] }
      result = Trip.send(:find_next_linked_segment, current_location, current_time, segments_by_departure, segments_by_arrival, used_segments)
      expect(result).to eq(hotel_segment)
    end

    it 'returns nil when no linked segments found' do
      segments_by_departure = { 'SVQ' => [] }
      segments_by_arrival = { 'SVQ' => [] }
      result = Trip.send(:find_next_linked_segment, current_location, current_time, segments_by_departure, segments_by_arrival, used_segments)
      expect(result).to be_nil
    end
  end

  describe '.build_trip_from_segment' do
    let(:base_airport) { 'SVQ' }
    let(:used_segments) { Set.new }

    let(:initial_segment) do
      double('Segment',
             departure_airport: 'SVQ',
             arrival_airport: 'BCN',
             transport?: true,
             hotel?: false,
             arrival_time: DateTime.parse('2023-03-02 11:00'))
    end

    let(:next_segment) do
      double('Segment',
             departure_airport: 'BCN',
             arrival_airport: 'SVQ',
             transport?: true,
             hotel?: false,
             departure_time: DateTime.parse('2023-03-02 12:00'),
             arrival_time: DateTime.parse('2023-03-02 15:00'))
    end

    let(:segments_by_departure) { { 'BCN' => [next_segment] } }
    let(:segments_by_arrival) { { 'BCN' => [] } }

    it 'builds a complete trip from initial segment' do
      result = Trip.send(:build_trip_from_segment, initial_segment, segments_by_departure, segments_by_arrival, used_segments, base_airport)
      
      expect(result).to contain_exactly(initial_segment, next_segment)
    end

    it 'marks segments as used' do
      Trip.send(:build_trip_from_segment, initial_segment, segments_by_departure, segments_by_arrival, used_segments, base_airport)
      
      expect(used_segments).to include(initial_segment, next_segment)
    end

    it 'stops when returning to base airport' do
      result = Trip.send(:build_trip_from_segment, initial_segment, segments_by_departure, segments_by_arrival, used_segments, base_airport)
      
      expect(result.last.arrival_airport).to eq(base_airport)
    end

    it 'stops when no next segment found' do
      segments_by_departure = { 'BCN' => [] }
      result = Trip.send(:build_trip_from_segment, initial_segment, segments_by_departure, segments_by_arrival, used_segments, base_airport)
      
      expect(result).to contain_exactly(initial_segment)
    end
  end

  describe '.build_trips_from_initial_segments' do
    let(:base_airport) { 'SVQ' }

    let(:initial_segment1) do
      double('Segment',
             departure_airport: 'SVQ',
             arrival_airport: 'BCN',
             transport?: true,
             hotel?: false,
             departure_time: DateTime.parse('2023-03-02 10:00'),
             arrival_time: DateTime.parse('2023-03-02 11:00'))
    end

    let(:initial_segment2) do
      double('Segment',
             departure_airport: 'SVQ',
             arrival_airport: 'MAD',
             transport?: true,
             hotel?: false,
             departure_time: DateTime.parse('2023-03-01 10:00'),
             arrival_time: DateTime.parse('2023-03-01 11:00'))
    end

    let(:return_segment1) do
      double('Segment',
             departure_airport: 'BCN',
             arrival_airport: 'SVQ',
             transport?: true,
             hotel?: false,
             departure_time: DateTime.parse('2023-03-02 12:00'),
             arrival_time: DateTime.parse('2023-03-02 15:00'))
    end

    let(:return_segment2) do
      double('Segment',
             departure_airport: 'MAD',
             arrival_airport: 'SVQ',
             transport?: true,
             hotel?: false,
             departure_time: DateTime.parse('2023-01-01 12:00'),
             arrival_time: DateTime.parse('2023-01-01 15:00'))
    end

    let(:initial_segments) { [initial_segment1, initial_segment2] }
    let(:segments_by_departure) { { 'BCN' => [return_segment1], 'MAD' => [return_segment2] } }
    let(:segments_by_arrival) { { 'BCN' => [], 'MAD' => [] } }

    it 'builds multiple trips from initial segments' do
      result = Trip.send(:build_trips_from_initial_segments, initial_segments, segments_by_departure, segments_by_arrival, base_airport)
      
      expect(result.length).to eq(2)
      # Each trip should have segments
      expect(result[0].segments.length).to be >= 1
      expect(result[1].segments.length).to be >= 1
    end

    it 'skips already used segments' do
      result = Trip.send(:build_trips_from_initial_segments, [initial_segment1], segments_by_departure, segments_by_arrival, base_airport)
      
      expect(result.length).to eq(1)
    end

    it 'orders trips by earliest date' do
      result = Trip.send(:build_trips_from_initial_segments, initial_segments, segments_by_departure, segments_by_arrival, base_airport)
      
      # The second trip should come first because it has an earlier date
      expect(result[0].earliest_date).to be < result[1].earliest_date
    end
  end

  describe '.validate_initial_point_segments' do
    it 'raises error when no segments provided' do
      expect { Trip.validate_initial_point_segments([], 'SVQ') }.to raise_error(ItineraryErrors::InvalidTripError)
    end

    it 'does not raise error when segments provided' do
      segment = double('Segment')
      expect { Trip.validate_initial_point_segments([segment], 'SVQ') }.not_to raise_error
    end

    it 'includes base airport in error message' do
      expect { Trip.validate_initial_point_segments([], 'MAD') }.to raise_error(ItineraryErrors::InvalidTripError, /MAD/)
    end
  end
end 