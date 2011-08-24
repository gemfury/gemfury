require 'gemfury/const'
require 'gemfury/configuration'
require 'gemfury/platform'
require 'gemfury/client'
require 'gemfury/version'

module Gemfury
  extend Configuration
  class << self
    # Alias for Gemfury::Client.new
    #
    # @return [Gemfury::Client]
    def new(options={})
      Gemfury::Client.new(options)
    end

    # Delegate to Twitter::Client
    def method_missing(method, *args, &block)
      return super unless new.respond_to?(method)
      new.send(method, *args, &block)
    end

    def respond_to?(method, include_private = false)
      new.respond_to?(method, include_private) || super(method, include_private)
    end
  end
end