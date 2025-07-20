# frozen_string_literal: true

require 'rspec'
require 'date'

# Add the lib directory to the load path
$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

# Load all files in the lib directory
Dir[File.expand_path('../lib/*.rb', __dir__)].each { |file| require file }

# RSpec.configure do |config|
#   # Enable flags like --only-failures and --next-failure
#   config.example_status_persistence_file_path = '.rspec_status'

#   # Disable RSpec exposing methods globally on `Module` and `main`
#   config.disable_monkey_patching!

#   config.expect_with :rspec do |c|
#     c.syntax = :expect
#   end
# end
