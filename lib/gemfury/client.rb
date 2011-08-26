module Gemfury
  class Client
    include Gemfury::Auth
    attr_accessor *Configuration::VALID_OPTIONS_KEYS

    # Creates a new API
    def initialize(options={})
      options = Gemfury.options.merge(options)
      Configuration::VALID_OPTIONS_KEYS.each do |key|
        send("#{key}=", options[key])
      end
    end

    def check_version
      response = connection.get('status/version')
      ensure_successful_response(response)

      current = Gem::Version.new(Gemfury::VERSION)
      latest = Gem::Version.new(response.body['version'])

      unless latest.eql?(current)
        raise InvalidGemVersion.new('Please update your gem')
      end
    end

    def push_gem(gem_file, options = {})
      with_authentication do
        response = connection.post('gems', options.merge(
          :gem_file => gem_file
        ))

        ensure_successful_response(response)
      end
    end

  private
    def connection(options = {})
      options = {
        :url => self.endpoint,
        :ssl => { :verify => false },
        :headers => {
          :accept => 'application/json',
          :user_agent => user_agent
        }
      }.merge(options)

      if self.user_api_key
        options[:headers][:authorization] = self.user_api_key
      end

      Faraday.new(options) do |builder|
        builder.use Faraday::Request::MultipartWithFile
        builder.use Faraday::Request::Multipart
        builder.use Faraday::Request::UrlEncoded
        #builder.use Faraday::Response::Logger
        builder.use Faraday::Response::ParseJson
        builder.adapter :net_http
      end
    end

    def ensure_successful_response(response)
      unless response.success?
        raise(case response.status
          when 401 then Gemfury::Unauthorized
          else          Gemfury::Error
        end)
      end
    end
  end
end