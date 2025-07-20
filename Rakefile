# frozen_string_literal: true

require 'rspec/core/rake_task'
require 'rubocop/rake_task'

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new(:rubocop)

desc 'Run all checks'
task check: %i[rubocop spec]

desc 'Run tests with coverage'
task :test do
  Rake::Task[:spec].invoke
end

desc 'Install dependencies'
task :install do
  system('bundle install')
end

desc 'Setup development environment'
task setup: %i[install check] do
  puts 'Development environment setup complete!'
end

desc 'Run code challenge with base airport (default SVQ, use BASED=IATA to change)'
task :run do
  base_airport = ENV['BASED'] || 'SVQ'
  system("BASED=#{base_airport} bundle exec ruby main.rb input.txt")
end

desc 'Run code challenge with all test inputs in inputs folder'
task :run_test_inputs do
  base_airport = ENV['BASED'] || 'SVQ'
  Dir.glob('inputs/*.txt').each do |input_file|
    command = "BASED=#{base_airport} bundle exec ruby main.rb #{input_file}"
    puts "Running command: #{command}"
    puts "\nProcessing #{input_file}..."
    begin
      system(command)
    rescue StandardError => e
      puts "Error processing #{input_file}: #{e.message}"
    end
    puts '-' * 50
  end
end
