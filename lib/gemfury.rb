# frozen_string_literal: true

gem 'multi_json',         '~> 1.10'
gem 'netrc',              '>= 0.10.0', '< 0.12.0.pre'
gem 'faraday',            '>= 2.0.0', '< 3.0.0.pre'
gem 'faraday-multipart',  '>= 1.0.0', '< 2.0.0.pre'

require 'time'
require 'cgi'
require 'uri'
require 'netrc'
require 'multi_json'
require 'faraday'
require 'faraday/multipart'
require 'faraday/adapter/fury_http'
require 'faraday/request/multipart_with_file'

require 'gemfury/version'
require 'gemfury/const'
require 'gemfury/error'
require 'gemfury/platform'
require 'gemfury/configuration'

require 'gemfury/client/filters'
require 'gemfury/client/middleware'
require 'gemfury/client'

module Gemfury
  extend Configuration
  VALID_OPTIONS_KEYS = Configuration::CONFIGURATION_DEFAULTS.keys.freeze

  class << self
    # Alias for Gemfury::Client.new
    #
    # @return [Gemfury::Client]
    def new(options = {})
      Gemfury::Client.new(options)
    end

    # Convenience method to allow configuration options to be set in a block
    def configure
      yield self
    end

    # Create a hash of options and their values
    # @return [Hash] the options and their values
    def options
      VALID_OPTIONS_KEYS.each_with_object({}) do |k, options|
        options[k] = send(k)
      end
    end

    # Reset all configuration options to defaults
    # @return [Configuration] The default configuration
    def reset
      CONFIGURATION_DEFAULTS.each { |k, v| send("#{k}=", v) }
      self
    end

    # Delegate to Gemfury::Client
    def method_missing(method, *args, &block)
      return super unless new.respond_to?(method)

      new.send(method, *args, &block)
    end

    def respond_to?(method, include_private = false)
      new.respond_to?(method, include_private) || super
    end
  end
end

# Initialize configuration
Gemfury.reset

# Polyfill #dig for Ruby 2.2 and earlier
class Hash
  unless instance_methods.include?(:dig)
    def dig(*parts)
      parts.inject(self) do |hash, part|
        hash.is_a?(Hash) ? hash[part] : nil
      end
    end
  end
end
