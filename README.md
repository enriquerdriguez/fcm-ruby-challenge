# README
# FCM Digital - Ruby Technical Challenge

This repository contains the implementation of an itinerary processing system for the [FCM Digital code challenge](https://github.com/fcm-digital/ruby_technical_challenge), which transforms raw reservation data into organized trip itineraries. The system processes flight, train, and hotel segments to create comprehensive trip representations based on a user's base airport.

## Table of Contents

- [Requirements](#requirements)
- [Getting Started](#getting-started)
- [Technical Decisions & Architecture](#technical-decisions--architecture)
- [Usage](#usage)
- [Features](#features)
- [Testing](#testing)
- [Error Handling](#error-handling)
- [General Observations](#general-observations)

## Requirements

- Ruby (version 3.1.4)
- Bundler for dependency management
- RSpec for testing (included in Gemfile)
- Docker (optional)

## Getting Started

Follow these steps to get the project up and running:

1. Install required gems:

   ```bash
   bundle install
   ```

2. Run the tests to ensure everything is working:

   ```bash
   bundle exec rspec
   ```

3. Execute the application with the sample input:

   ```bash
   BASED=SVQ bundle exec ruby main.rb input.txt
   ```

## Technical Decisions & Architecture

### Core Design Principles
- **Single Responsibility Principle**: Each class has a clear, focused responsibility
- **Separation of Concerns**: File processing, segment parsing, and trip grouping are handled by separate classes
- **Error Handling**: Comprehensive custom error classes for different failure scenarios
- **Extensibility**: Easy to add new segment types or modify processing logic

### Architecture Overview
- **MainApp**: Entry point that orchestrates the application flow
- **ItineraryProcessor**: Handles file reading and coordinates the processing pipeline
- **Segment**: Represents individual travel segments (Flight, Train, Hotel) with parsing and validation
- **Trip**: Groups related segments into logical trips with destination determination
- **Error Classes**: Custom error hierarchy for specific failure scenarios

### Key Technical Decisions
- **IATA Code Validation**: Strict validation using regex patterns to ensure 3-letter uppercase codes
- **DateTime Handling**: Robust parsing with proper error handling for malformed dates
- **Connection Logic**: Implements 24-hour connection window for transport segments
- **Sorting Strategy**: Chronological sorting by departure time for transport and check-in date for hotels
- **Memory Efficiency**: Processes segments in a single pass to minimize memory usage and uses optimal search for grouping segments into trips

### Performance Considerations

When thinking about the solution for this challenge, the first thing that came to mind was to filter segments by the initial point and then loop through the rest of the segments to find the next linked segment.
My first approach looked like this:
```bash
  def self.group_segments(segments, base_airport)
    return [] if segments.empty?

    # Sort all segments chronologically by start time to process them in order
    sorted = Segment.sort_by_date(segments)

    # each trip should start with a transport segment leaving the base IATA
    initial_point_segments = sorted.select { |segment| segment.departure_airport == base_airport }
    validate_initial_point_segments(initial_point_segments, base_airport)

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
```

But after it was working, I realized it was not the most optimal solution. The search for the next linked segment could be improved by using hash maps to filter by IATA and then checking if the segment was already used. So I decided to refactor the code to use that approach, improving the execution times.

## Usage

### Basic Usage
The application processes input files containing reservation segments and outputs organized trips:

```bash
BASED=SVQ bundle exec ruby main.rb input.txt
```

### Rake Tasks
I have also created some rake tasks to make it easier to run various scenarios and tests:

```bash
rake run # Will run BASED=SVQ bundle exec ruby main.rb input.txt
rake run_test_inputs # Will run scenarios in the inputs folder
rake test # Will run rspecs
```

### Docker

This application can be run in Docker. For that, you only need to run the following commands:

```bash
docker-compose build
docker-compose run fcm-app bash

# Execute normal usage inside the bash
BASED=SVQ bundle exec ruby main.rb input.txt
```

### Input Format
The system expects input files with the following format:

```
RESERVATION
SEGMENT: Flight SVQ 2023-03-02 06:40 -> BCN 09:10

RESERVATION
SEGMENT: Hotel BCN 2023-01-05 -> 2023-01-10

RESERVATION
SEGMENT: Flight SVQ 2023-01-05 20:40 -> BCN 22:10
SEGMENT: Flight BCN 2023-01-10 10:30 -> SVQ 11:50
```

### Output Format
The system generates organized trip itineraries:

```
TRIP to BCN
Flight from SVQ to BCN at 2023-01-05 20:40 to 22:10
Hotel at BCN on 2023-01-05 to 2023-01-10
Flight from BCN to SVQ at 2023-01-10 10:30 to 11:50

TRIP to MAD
Train from SVQ to MAD at 2023-02-15 09:30 to 11:00
Hotel at MAD on 2023-02-15 to 2023-02-17
Train from MAD to SVQ at 2023-02-17 17:00 to 19:30
```

### Environment Variables
- `BASED`: Required environment variable specifying the base airport IATA code (e.g., SVQ, BCN, MAD)

## Features

### Trip Grouping Logic
- **Connection Detection**: Automatically groups segments that are within 24 hours of each other
- **Destination Determination**: Identifies the final destination of each trip
- **Chronological Ordering**: Sorts trips by earliest departure time
- **Base Airport Handling**: Groups segments starting from the specified base airport

### Validation Features
- **IATA Code Validation**: Ensures all airport codes are valid 3-letter uppercase codes
- **Date/Time Validation**: Validates date formats and logical date relationships
- **Segment Type Validation**: Ensures only supported segment types are processed
- **Trip Integrity**: Validates that trips can be properly formed from available segments

## Testing

Tests were written using the RSpec library. I tried to cover every method with unit tests and also included some integration tests.

### Running Tests
```bash
# Run all tests
bundle exec rspec

# Run specific test files
bundle exec rspec spec/lib/segment_spec.rb
bundle exec rspec spec/integration_spec.rb
```

### Running Tests with Docker

```bash
docker-compose build
docker-compose run fcm-app bash

# Execute tests inside the bash
bundle exec rspec
```

### Integration Tests
I added some particular scenarios that could happen with incorrect inputs. They are inside the inputs folder. They can be run both with RSpec or a rake task.

```bash
# Normal bash
bundle exec rspec spec/integration_spec.rb

# Docker
docker-compose build
docker-compose run fcm-app bash
bundle exec rspec spec/integration_spec.rb

# Rake task
bundle exec rake run_test_inputs
```

## Error Handling

### Custom Error Classes
The application implements a comprehensive error hierarchy:

- **ItineraryError**: Base error class for all itinerary-related errors
- **InvalidSegmentError**: Raised for malformed segment data
- **DateTimeParseError**: Raised for invalid date/time formats
- **InvalidIataCodeError**: Raised for invalid airport codes
- **InvalidTripError**: Raised when trips cannot be properly formed

### Error Scenarios Handled
- Invalid segment types (e.g., "AIRBNB")
- Malformed IATA codes (e.g., "SQ" instead of "SVQ")
- Invalid date formats
- Logical date errors (check-out before check-in)
- Missing base airport segments

## General Observations

The solution prioritizes **readability**, **maintainability**, **extensibility**, and **efficiency**. The code structure allows for easy addition of new segment types and modification of grouping logic without significant refactoring.

The error handling is comprehensive, providing clear feedback for various failure scenarios. The test coverage ensures reliability and helps prevent regressions during future development.

While the current implementation handles the core requirements effectively, there are opportunities to improve this code.

### Future Improvements

#### Code Quality Improvements
- **Factory Pattern**: Implement factory pattern for segment creation
- **Trip Model**: I chose to keep all the trip-building logic within the Trip class rather than extracting it into concerns or modules. This decision was made with the following considerations:
  - **Reviewer-friendly**: All the trip-building algorithm is visible in one place, making it easy for reviewers to understand the complete logic
  - **Time-efficient**: Focuses on solving the core problem rather than over-engineering the architecture
  - **Clear algorithm flow**: The entire trip-building process is easy to follow and trace
  - **Production considerations:**
      In a production environment, I would refactor this by:
      - Extracting trip-building logic into a `TripBuilderService` or similar service object
      - Creating separate concerns for different aspects (e.g., `SegmentLinking`, `TripValidation`)
      - Making individual components more testable and maintainable
      - Following better separation of concerns principles
- **Logging**: Comprehensive logging for debugging and monitoring
- **Testing**: Use Factories
