require 'webmock/rspec'
require 'gemfury'
require 'gemfury/command'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[File.expand_path("../support/**/*.rb", __FILE__)].each { |f| require f }

RSpec.configure do |config|
  # == Mock Framework
  config.mock_with :rspec
  # == Suppress Thor Errors
  config.before(:each) do
    MyApp.instance_variable_set(:@no_commands, true)
  end
end
