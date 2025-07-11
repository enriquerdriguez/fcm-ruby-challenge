# frozen_string_literal: true

# Main application class that will wrap the whole app
class MainApp
  def self.run
    new.run
  end

  def run
    input_file = ARGV[0]

    if input_file.nil?
      puts 'Warning: No input file provided'
      exit 1
    end

    input_file_content = File.read(input_file)
    puts input_file_content
  end
end

# Run the whole app when the file is executed directly
MainApp.run if __FILE__ == $PROGRAM_NAME
