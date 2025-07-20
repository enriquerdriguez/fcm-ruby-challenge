# README
# FCM Digital - Ruby Technical Challenge

This repository contains the implementation of an itinerary processing system for FCM Digital, which transforms raw reservation data into organized trip itineraries. The system processes flight, train, and hotel segments to create comprehensive trip representations based on a user's base airport.

## Table of Contents

- [Requirements](#requirements)
- [Getting Started](#getting-started)
- [Technical Decisions & Architecture](#technical-decisions)
- [Usage](#usage)
- [Features](#features)
- [Testing](#testing)
- [Error Handling](#error-handling)
- [Performance Considerations](#performance)
- [Future Improvements](#improvements)

## Requirements

- Ruby (version 3.1.4)
- Bundler for dependency management
- RSpec for testing (included in Gemfile)

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
- **Memory Efficiency**: Processes segments in a single pass to minimize memory usage

## Usage

### Basic Usage
The application processes input files containing reservation segments and outputs organized trips:

```bash
BASED=SVQ bundle exec ruby main.rb input.txt
```

### Docker

This application can be run in docker. For that you only need to run the following commands:

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

### Supported Segment Types
- **Flight**: Air travel segments with departure/arrival times
- **Train**: Rail travel segments with departure/arrival times  
- **Hotel**: Accommodation segments with check-in/check-out dates

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

Tests were written using the library rspec. I tried to cover every method with unit tests and also some integration tests.


### Running Tests
```bash
# Run all tests
bundle exec rspec

# Run specific test files
bundle exec rspec spec/lib/segment_spec.rb
bundle exec rspec spec/integration_spec.rb
```
### Running tests with docker


```bash
docker-compose build
docker-compose run fcm-app bash

# Execute normal usage inside the bash
bundle exec rspec
```

### Integration tests
I added some particular scenarios that could happen with wrong inputs. They are inside the inputs folder. They can be run both with Rspec or a rake task.

```bash
# Normal bash
bundle exec rspec spec/integration_spec.rb

# docker
docker-compose build
docker-compose run fcm-app bash
bundle exec rspec spec/integration_spec.rb

# rake task
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

## Performance Considerations
## Future Improvements
## General Observations
