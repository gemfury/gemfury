gem "multi_json",         "~> 1.10"
gem "faraday",            ">= 0.9.0", "< 0.16.0.pre"
gem "netrc",              ">= 0.10.0", "< 0.12.0.pre"

require 'cgi'
require 'uri'
require 'netrc'
require 'multi_json'
require 'faraday'
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
  class << self
    # Alias for Gemfury::Client.new
    #
    # @return [Gemfury::Client]
    def new(options={})
      Gemfury::Client.new(options)
    end

    # Delegate to Gemfury::Client
    def method_missing(method, *args, &block)
      return super unless new.respond_to?(method)
      new.send(method, *args, &block)
    end

    def respond_to?(method, include_private = false)
      new.respond_to?(method, include_private) || super(method, include_private)
    end
  end
end

class Hash
  # Access nested hashes as a period-separated path
  def path(path, separator = '.')
    path.split(separator).inject(self) do |hash, part|
      hash.is_a?(Hash) ? hash[part] : nil
    end
  end
end