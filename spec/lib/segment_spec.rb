# frozen_string_literal: true
# rubocop:disable all

require 'spec_helper'
require_relative '../../lib/segment'

RSpec.describe Segment do
  describe 'validation' do
    context 'transport segments' do
      it 'raises error when missing departure time' do
        expect do
          Segment.new(type: 'Flight', departure_airport: 'SVQ', arrival_airport: 'BCN',
                     arrival_time: DateTime.now)
        end.to raise_error(ItineraryErrors::InvalidSegmentError, /Transport segments must have departure and arrival times/)
      end

      it 'raises error when missing arrival time' do
        expect do
          Segment.new(type: 'Flight', departure_airport: 'SVQ', arrival_airport: 'BCN',
                     departure_time: DateTime.now)
        end.to raise_error(ItineraryErrors::InvalidSegmentError, /Transport segments must have departure and arrival times/)
      end
    end

    context 'hotel segments' do
      it 'raises error when missing check-in date' do
        expect do
          Segment.new(type: 'Hotel', arrival_airport: 'BCN',
                     check_out_date: Date.today + 1)
        end.to raise_error(ItineraryErrors::InvalidSegmentError, /Hotel segments must have check-in and check-out dates/)
      end

      it 'raises error when missing check-out date' do
        expect do
          Segment.new(type: 'Hotel', arrival_airport: 'BCN',
                     check_in_date: Date.today)
        end.to raise_error(ItineraryErrors::InvalidSegmentError, /Hotel segments must have check-in and check-out dates/)
      end
    end

    context 'invalid segment types' do
      it 'raises error for invalid segment type' do
        expect do
          Segment.new(type: 'InvalidType', departure_airport: 'SVQ', arrival_airport: 'BCN',
                     departure_time: DateTime.now, arrival_time: DateTime.now + Rational(1, 24))
        end.to raise_error(ItineraryErrors::InvalidSegmentError, /Invalid segment type: InvalidType/)
      end
    end

    context 'invalid IATA codes' do
      it 'raises error for invalid departure airport code' do
        expect do
          Segment.new(type: 'Flight', departure_airport: 'SV', arrival_airport: 'BCN',
                     departure_time: DateTime.now, arrival_time: DateTime.now + Rational(1, 24))
        end.to raise_error(ItineraryErrors::InvalidSegmentError, /Invalid departure_airport: SV/)
      end

      it 'raises error for invalid arrival airport code' do
        expect do
          Segment.new(type: 'Flight', departure_airport: 'SVQ', arrival_airport: 'BC',
                     departure_time: DateTime.now, arrival_time: DateTime.now + Rational(1, 24))
        end.to raise_error(ItineraryErrors::InvalidSegmentError, /Invalid arrival_airport: BC/)
      end

      it 'raises error for lowercase IATA code' do
        expect do
          Segment.new(type: 'Flight', departure_airport: 'svq', arrival_airport: 'BCN',
                     departure_time: DateTime.now, arrival_time: DateTime.now + Rational(1, 24))
        end.to raise_error(ItineraryErrors::InvalidSegmentError, /Invalid departure_airport: svq/)
      end

      it 'raises error for invalid hotel airport code' do
        expect do
          Segment.new(type: 'Hotel', arrival_airport: 'BC',
                     check_in_date: Date.today, check_out_date: Date.today + 1)
        end.to raise_error(ItineraryErrors::InvalidSegmentError, /Invalid arrival_airport: BC/)
      end
    end

    context 'hotel date validation' do
      it 'raises error when check-in date is after check-out date' do
        expect do
          Segment.new(type: 'Hotel', arrival_airport: 'BCN',
                     check_in_date: Date.today + 2, check_out_date: Date.today + 1)
        end.to raise_error(ItineraryErrors::InvalidSegmentError, /Check-in date must be before check-out date/)
      end

      it 'raises error when check-in date equals check-out date' do
        expect do
          Segment.new(type: 'Hotel', arrival_airport: 'BCN',
                     check_in_date: Date.today, check_out_date: Date.today)
        end.to raise_error(ItineraryErrors::InvalidSegmentError, /Check-in date must be before check-out date/)
      end
    end
  end

  describe '#transport?' do
    it 'returns true for Flight segments' do
      segment = Segment.new(type: 'Flight', departure_airport: 'SVQ', arrival_airport: 'BCN',
                           departure_time: DateTime.now, arrival_time: DateTime.now + Rational(1, 24))
      expect(segment.transport?).to be true
    end

    it 'returns true for Train segments' do
      segment = Segment.new(type: 'Train', departure_airport: 'SVQ', arrival_airport: 'MAD',
                           departure_time: DateTime.now, arrival_time: DateTime.now + Rational(1, 24))
      expect(segment.transport?).to be true
    end

    it 'returns false for Hotel segments' do
      segment = Segment.new(type: 'Hotel', arrival_airport: 'BCN',
                           check_in_date: Date.today, check_out_date: Date.today + 1)
      expect(segment.transport?).to be false
    end
  end

  describe '#hotel?' do
    it 'returns true for Hotel segments' do
      segment = Segment.new(type: 'Hotel', arrival_airport: 'BCN',
                           check_in_date: Date.today, check_out_date: Date.today + 1)
      expect(segment.hotel?).to be true
    end

    it 'returns false for Flight segments' do
      segment = Segment.new(type: 'Flight', departure_airport: 'SVQ', arrival_airport: 'BCN',
                           departure_time: DateTime.now, arrival_time: DateTime.now + Rational(1, 24))
      expect(segment.hotel?).to be false
    end

    it 'returns false for Train segments' do
      segment = Segment.new(type: 'Train', departure_airport: 'SVQ', arrival_airport: 'MAD',
                           departure_time: DateTime.now, arrival_time: DateTime.now + Rational(1, 24))
      expect(segment.hotel?).to be false
    end
  end

  describe '#departure_date' do
    it 'returns the departure date for transport segments' do
      departure_time = DateTime.parse('2023-03-02 06:40')
      segment = Segment.new(type: 'Flight', departure_airport: 'SVQ', arrival_airport: 'BCN',
                           departure_time: departure_time, arrival_time: departure_time + Rational(2, 24))
      expect(segment.departure_date).to eq(Date.parse('2023-03-02'))
    end

    it 'returns nil for hotel segments' do
      segment = Segment.new(type: 'Hotel', arrival_airport: 'BCN',
                           check_in_date: Date.today, check_out_date: Date.today + 1)
      expect(segment.departure_date).to be_nil
    end
  end

  describe '#arrival_date' do
    it 'returns the arrival date for transport segments' do
      arrival_time = DateTime.parse('2023-03-02 09:10')
      segment = Segment.new(type: 'Flight', departure_airport: 'SVQ', arrival_airport: 'BCN',
                           departure_time: arrival_time - Rational(2, 24), arrival_time: arrival_time)
      expect(segment.arrival_date).to eq(Date.parse('2023-03-02'))
    end

    it 'returns nil for hotel segments' do
      segment = Segment.new(type: 'Hotel', arrival_airport: 'BCN',
                           check_in_date: Date.today, check_out_date: Date.today + 1)
      expect(segment.arrival_date).to be_nil
    end
  end

  describe '#to_s' do
    it 'formats transport segments correctly' do
      segment = Segment.new(type: 'Flight', departure_airport: 'SVQ', arrival_airport: 'BCN',
                           departure_time: DateTime.parse('2023-03-02 06:40'),
                           arrival_time: DateTime.parse('2023-03-02 09:10'))
      expected = 'Flight from SVQ to BCN at 2023-03-02 06:40 to 09:10'
      expect(segment.to_s).to eq(expected)
    end

    it 'formats hotel segments correctly' do
      segment = Segment.new(type: 'Hotel', arrival_airport: 'BCN',
                           check_in_date: Date.parse('2023-01-05'),
                           check_out_date: Date.parse('2023-01-10'))
      expected = 'Hotel at BCN on 2023-01-05 to 2023-01-10'
      expect(segment.to_s).to eq(expected)
    end
  end

  describe '.sort_by_date' do
    it 'sorts segments by departure time for transport segments' do
      segment1 = Segment.new(type: 'Flight', departure_airport: 'SVQ', arrival_airport: 'BCN',
                             departure_time: DateTime.parse('2023-03-02 06:40'),
                             arrival_time: DateTime.parse('2023-03-02 09:10'))
      segment2 = Segment.new(type: 'Flight', departure_airport: 'BCN', arrival_airport: 'NYC',
                             departure_time: DateTime.parse('2023-03-02 15:00'),
                             arrival_time: DateTime.parse('2023-03-02 22:45'))
      segment3 = Segment.new(type: 'Flight', departure_airport: 'SVQ', arrival_airport: 'MAD',
                             departure_time: DateTime.parse('2023-03-01 10:00'),
                             arrival_time: DateTime.parse('2023-03-01 11:30'))

      sorted = Segment.sort_by_date([segment1, segment2, segment3])
      expect(sorted).to eq([segment3, segment1, segment2])
    end

    it 'sorts segments by check-in date for hotel segments' do
      segment1 = Segment.new(type: 'Hotel', arrival_airport: 'BCN',
                             check_in_date: Date.parse('2023-01-05'),
                             check_out_date: Date.parse('2023-01-10'))
      segment2 = Segment.new(type: 'Hotel', arrival_airport: 'MAD',
                             check_in_date: Date.parse('2023-02-15'),
                             check_out_date: Date.parse('2023-02-17'))
      segment3 = Segment.new(type: 'Hotel', arrival_airport: 'NYC',
                             check_in_date: Date.parse('2023-01-01'),
                             check_out_date: Date.parse('2023-01-03'))

      sorted = Segment.sort_by_date([segment1, segment2, segment3])
      expect(sorted).to eq([segment3, segment1, segment2])
    end

    it 'sorts mixed segments correctly' do
      flight = Segment.new(type: 'Flight', departure_airport: 'SVQ', arrival_airport: 'BCN',
                           departure_time: DateTime.parse('2023-03-02 06:40'),
                           arrival_time: DateTime.parse('2023-03-02 09:10'))
      hotel = Segment.new(type: 'Hotel', arrival_airport: 'BCN',
                          check_in_date: Date.parse('2023-01-05'),
                          check_out_date: Date.parse('2023-01-10'))
      train = Segment.new(type: 'Train', departure_airport: 'SVQ', arrival_airport: 'MAD',
                          departure_time: DateTime.parse('2023-02-15 09:30'),
                          arrival_time: DateTime.parse('2023-02-15 11:00'))

      sorted = Segment.sort_by_date([flight, hotel, train])
      expect(sorted).to eq([hotel, train, flight])
    end
  end

  describe '.validate_segment_line' do
    it 'validates correct segment format' do
      line = 'SEGMENT: Flight SVQ 2023-03-02 06:40 -> BCN 09:10'
      expect { Segment.validate_segment_line(line) }.not_to raise_error
    end

    it 'raises error for lines not starting with SEGMENT:' do
      line = 'Flight SVQ 2023-03-02 06:40 -> BCN 09:10'
      expect { Segment.validate_segment_line(line) }.to raise_error(ItineraryErrors::InvalidSegmentError, /Invalid segment format/)
    end

    it 'raises error for invalid segment type' do
      line = 'SEGMENT: InvalidType SVQ 2023-03-02 06:40 -> BCN 09:10'
      expect { Segment.validate_segment_line(line) }.to raise_error(ItineraryErrors::InvalidSegmentError, /Invalid segment type: InvalidType/)
    end
  end

  describe '.parse_transport_segment' do
    it 'parses flight segment correctly' do
      parts = ['Flight', 'SVQ', '2023-03-02', '06:40', '->', 'BCN', '09:10']
      segment = Segment.parse_transport_segment(parts)

      expect(segment.type).to eq('Flight')
      expect(segment.departure_airport).to eq('SVQ')
      expect(segment.arrival_airport).to eq('BCN')
      expect(segment.departure_time).to eq(DateTime.parse('2023-03-02 06:40'))
      expect(segment.arrival_time).to eq(DateTime.parse('2023-03-02 09:10'))
    end

    it 'parses train segment correctly' do
      parts = ['Train', 'SVQ', '2023-02-15', '09:30', '->', 'MAD', '11:00']
      segment = Segment.parse_transport_segment(parts)

      expect(segment.type).to eq('Train')
      expect(segment.departure_airport).to eq('SVQ')
      expect(segment.arrival_airport).to eq('MAD')
      expect(segment.departure_time).to eq(DateTime.parse('2023-02-15 09:30'))
      expect(segment.arrival_time).to eq(DateTime.parse('2023-02-15 11:00'))
    end

    it 'handles overnight flights correctly' do
      parts = ['Flight', 'SVQ', '2023-03-02', '23:40', '->', 'BCN', '02:10']
      segment = Segment.parse_transport_segment(parts)

      expect(segment.departure_time).to eq(DateTime.parse('2023-03-02 23:40'))
      expect(segment.arrival_time).to eq(DateTime.parse('2023-03-03 02:10'))
    end
  end

  describe '.parse_hotel_segment' do
    it 'parses hotel segment correctly' do
      parts = ['Hotel', 'BCN', '2023-01-05', '->', '2023-01-10']
      segment = Segment.parse_hotel_segment(parts)

      expect(segment.type).to eq('Hotel')
      expect(segment.arrival_airport).to eq('BCN')
      expect(segment.check_in_date).to eq(Date.parse('2023-01-05'))
      expect(segment.check_out_date).to eq(Date.parse('2023-01-10'))
    end
  end

  describe '.extract_transport_attributes' do
    it 'extracts attributes for regular flight' do
      parts = ['Flight', 'SVQ', '2023-03-02', '06:40', '->', 'BCN', '09:10']
      attributes = Segment.extract_transport_attributes(parts)

      expect(attributes[:type]).to eq('Flight')
      expect(attributes[:departure_airport]).to eq('SVQ')
      expect(attributes[:arrival_airport]).to eq('BCN')
      expect(attributes[:departure_time]).to eq(DateTime.parse('2023-03-02 06:40'))
      expect(attributes[:arrival_time]).to eq(DateTime.parse('2023-03-02 09:10'))
    end

    it 'handles overnight flights by adding one day to arrival' do
      parts = ['Flight', 'SVQ', '2023-03-02', '23:40', '->', 'BCN', '02:10']
      attributes = Segment.extract_transport_attributes(parts)

      expect(attributes[:departure_time]).to eq(DateTime.parse('2023-03-02 23:40'))
      expect(attributes[:arrival_time]).to eq(DateTime.parse('2023-03-03 02:10'))
    end
  end

  describe '.extract_hotel_attributes' do
    it 'extracts hotel attributes correctly' do
      parts = ['Hotel', 'BCN', '2023-01-05', '->', '2023-01-10']
      attributes = Segment.extract_hotel_attributes(parts)

      expect(attributes[:type]).to eq('Hotel')
      expect(attributes[:arrival_airport]).to eq('BCN')
      expect(attributes[:check_in_date]).to eq(Date.parse('2023-01-05'))
      expect(attributes[:check_out_date]).to eq(Date.parse('2023-01-10'))
    end
  end

  describe '.parse_datetime' do
    it 'parses valid datetime string' do
      datetime_str = '2023-03-02 06:40'
      result = Segment.parse_datetime(datetime_str)
      expect(result).to eq(DateTime.parse('2023-03-02 06:40'))
    end

    it 'raises error for nil datetime string' do
      expect { Segment.parse_datetime(nil) }.to raise_error(RuntimeError, /Datetime cannot be nil/)
    end

    it 'raises error for invalid datetime format' do
      expect { Segment.parse_datetime('invalid-datetime') }.to raise_error(ItineraryErrors::DateTimeParseError, /Invalid datetime format/)
    end
  end

  describe '.parse_date' do
    it 'parses valid date string' do
      date_str = '2023-01-05'
      result = Segment.parse_date(date_str)
      expect(result).to eq(Date.parse('2023-01-05'))
    end

    it 'raises error for nil date string' do
      expect { Segment.parse_date(nil) }.to raise_error(ItineraryErrors::DateTimeParseError, /Invalid date format for nil/)
    end

    it 'raises error for invalid date format' do
      expect { Segment.parse_date('invalid-date') }.to raise_error(ItineraryErrors::DateTimeParseError, /Invalid date format/)
    end
  end

  describe '.create_segment' do
    it 'creates a new segment with given attributes' do
      attributes = {
        type: 'Flight',
        departure_airport: 'SVQ',
        arrival_airport: 'BCN',
        departure_time: DateTime.parse('2023-03-02 06:40'),
        arrival_time: DateTime.parse('2023-03-02 09:10')
      }

      segment = Segment.create_segment(attributes)
      expect(segment).to be_a(Segment)
      expect(segment.type).to eq('Flight')
      expect(segment.departure_airport).to eq('SVQ')
      expect(segment.arrival_airport).to eq('BCN')
    end
  end

  describe '.overnight_flight?' do
    it 'returns true for overnight flight' do
      departure_time = DateTime.parse('2023-03-02 23:40')
      arrival_time = DateTime.parse('2023-03-02 02:10')
      expect(Segment.overnight_flight?(departure_time, arrival_time)).to be true
    end

    it 'returns false for same-day flight' do
      departure_time = DateTime.parse('2023-03-02 06:40')
      arrival_time = DateTime.parse('2023-03-02 09:10')
      expect(Segment.overnight_flight?(departure_time, arrival_time)).to be false
    end
  end

  describe '.parse' do
    context 'with valid transport segments' do
      it 'parses a flight segment correctly' do
        line = 'SEGMENT: Flight SVQ 2023-03-02 06:40 -> BCN 09:10'
        segment = Segment.parse(line)

        expect(segment.type).to eq('Flight')
        expect(segment.departure_airport).to eq('SVQ')
        expect(segment.arrival_airport).to eq('BCN')
        expect(segment.departure_time).to eq(DateTime.parse('2023-03-02 06:40'))
        expect(segment.arrival_time).to eq(DateTime.parse('2023-03-02 09:10'))
      end

      it 'parses a train segment correctly' do
        line = 'SEGMENT: Train SVQ 2023-02-15 09:30 -> MAD 11:00'
        segment = Segment.parse(line)

        expect(segment.type).to eq('Train')
        expect(segment.departure_airport).to eq('SVQ')
        expect(segment.arrival_airport).to eq('MAD')
        expect(segment.departure_time).to eq(DateTime.parse('2023-02-15 09:30'))
        expect(segment.arrival_time).to eq(DateTime.parse('2023-02-15 11:00'))
      end

      it 'handles overnight flights correctly' do
        line = 'SEGMENT: Flight SVQ 2023-03-02 23:40 -> BCN 02:10'
        segment = Segment.parse(line)

        expect(segment.departure_time).to eq(DateTime.parse('2023-03-02 23:40'))
        expect(segment.arrival_time).to eq(DateTime.parse('2023-03-03 02:10'))
      end
    end

    context 'with valid hotel segments' do
      it 'parses a hotel segment correctly' do
        line = 'SEGMENT: Hotel BCN 2023-01-05 -> 2023-01-10'
        segment = Segment.parse(line)

        expect(segment.type).to eq('Hotel')
        expect(segment.arrival_airport).to eq('BCN')
        expect(segment.check_in_date).to eq(Date.parse('2023-01-05'))
        expect(segment.check_out_date).to eq(Date.parse('2023-01-10'))
      end
    end

    context 'with invalid segment format' do
      it 'raises error for lines not starting with SEGMENT:' do
        line = 'Flight SVQ 2023-03-02 06:40 -> BCN 09:10'
        expect { Segment.parse(line) }.to raise_error(ItineraryErrors::InvalidSegmentError, /Invalid segment format/)
      end
    end

    context 'with invalid segment type' do
      it 'raises error for unsupported segment type' do
        line = 'SEGMENT: AIRBNB BCN 2023-01-10 10:30 -> SVQ 11:50'
        expect { Segment.parse(line) }.to raise_error(ItineraryErrors::InvalidSegmentError, /Invalid segment type: AIRBNB/)
      end
    end

    context 'with invalid IATA codes' do
      it 'raises error for invalid departure airport' do
        line = 'SEGMENT: Flight SQ 2023-03-02 06:40 -> BCN 09:10'
        expect { Segment.parse(line) }.to raise_error(ItineraryErrors::InvalidSegmentError, /Invalid departure_airport: SQ/)
      end

      it 'raises error for invalid arrival airport' do
        line = 'SEGMENT: Flight SVQ 2023-03-02 06:40 -> BC 09:10'
        expect { Segment.parse(line) }.to raise_error(ItineraryErrors::InvalidSegmentError, /Invalid arrival_airport: BC/)
      end

      it 'raises error for lowercase IATA code' do
        line = 'SEGMENT: Flight svq 2023-03-02 06:40 -> BCN 09:10'
        expect { Segment.parse(line) }.to raise_error(ItineraryErrors::InvalidSegmentError, /Invalid departure_airport: svq/)
      end
    end

    context 'with invalid date formats' do
      it 'raises error for invalid datetime format' do
        line = 'SEGMENT: Flight SVQ 2023-13-13 06:40 -> BCN 09:10'
        expect { Segment.parse(line) }.to raise_error(ItineraryErrors::DateTimeParseError, /Invalid datetime format/)
      end

      it 'raises error for missing date in hotel segment' do
        line = 'SEGMENT: Hotel MAD 2023-02-15 -> '
        expect { Segment.parse(line) }.to raise_error(ItineraryErrors::DateTimeParseError, /Invalid date format for nil/)
      end

      it 'raises error for invalid date format' do
        line = 'SEGMENT: Hotel MAD 2023-02-15 -> 2023-13-15'
        expect { Segment.parse(line) }.to raise_error(ItineraryErrors::DateTimeParseError, /Invalid date format/)
      end
    end

    context 'with invalid hotel dates' do
      it 'raises error when check-in date is after check-out date' do
        line = 'SEGMENT: Hotel MAD 2023-02-15 -> 2023-01-15'
        expect { Segment.parse(line) }.to raise_error(ItineraryErrors::InvalidSegmentError, /Check-in date must be before check-out date/)
      end

      it 'raises error when check-in date equals check-out date' do
        line = 'SEGMENT: Hotel MAD 2023-02-15 -> 2023-02-15'
        expect { Segment.parse(line) }.to raise_error(ItineraryErrors::InvalidSegmentError, /Check-in date must be before check-out date/)
      end
    end
  end
end
