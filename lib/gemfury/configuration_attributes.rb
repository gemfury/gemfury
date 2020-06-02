module Gemfury
  module ConfigurationAttributes

    CONFIGURATION_DEFAULTS = {
      :user_api_key => nil,
      :adapter => :net_http,
      :endpoint => 'https://api.fury.io/',
      :gitpoint => 'https://git.fury.io/',
      :pushpoint => 'https://push.fury.io/',
      :user_agent => "Gemfury RubyGem #{Gemfury::VERSION}",
      :api_version => 1,
      :account => nil
    }.freeze

    # user API key, also known as "full access token"
    # @return [String]
    attr_accessor :user_api_key

    # The adapter that will be used to connect
    # @return [Symbol]
    attr_accessor :adapter

    # The endpoint that will be used to connect
    # @return [String]
    attr_accessor :endpoint

    # The HTTP endpoint for git repo (used for .netrc credentials)
    # @return [String]
    attr_accessor :gitpoint

    # The endpoint for the Push API
    # @return [String]
    attr_accessor :pushpoint

    # The value sent in the 'User-Agent' header
    # @return [String]
    attr_accessor :user_agent

    # Gemfury remote API version
    # @return [Integer]
    attr_accessor :api_version

    # The account to impersonate, if you have permissions for multiple accounts
    # (If nil, no impersonation)
    # @return [String]
    attr_accessor :account

  end
end
