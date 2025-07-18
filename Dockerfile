# Use the official Ruby 3.1.4 image as base
FROM ruby:3.1.4-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    bash \
    && rm -rf /var/lib/apt/lists/*

# Copy Gemfile and Gemfile.lock
COPY Gemfile Gemfile.lock ./

# Install Ruby gems
RUN bundle install

# Copy the rest of the application
COPY . .