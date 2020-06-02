require 'gemfury/configuration_attributes'

module Gemfury
  # Defines constants and methods related to configuration
  module Configuration
    include Gemfury::ConfigurationAttributes

    # An array of valid keys in the options hash when configuring
    VALID_OPTIONS_KEYS = CONFIGURATION_DEFAULTS.keys.freeze

    # When this module is extended, set all configuration options to their default values
    def self.extended(base)
      base.reset
    end

    # Convenience method to allow configuration options to be set in a block
    def configure
      yield self
    end

    # Create a hash of options and their values
    # @return [Hash] the options and their values
    def options
      options = {}
      VALID_OPTIONS_KEYS.each{|k| options[k] = send(k)}
      options
    end

    # Reset all configuration options to defaults
    # @return [Configuration] The default configuration
    def reset
      CONFIGURATION_DEFAULTS.each { |k, v| send("#{k}=", v) }
      self
    end
  end
end
