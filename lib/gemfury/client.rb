module Gemfury
  class Client
    include Gemfury::Client::Filters
    attr_accessor *Configuration::VALID_OPTIONS_KEYS

    # Creates a new API
    def initialize(options={})
      options = Gemfury.options.merge(options)
      Configuration::VALID_OPTIONS_KEYS.each do |key|
        send("#{key}=", options[key])
      end
    end

    # Verify gem version
    def check_version
      response = connection.get('status/version')
      ensure_successful_response!(response)

      current = Gem::Version.new(Gemfury::VERSION)
      latest = Gem::Version.new(response.body['version'])

      unless latest.eql?(current)
        raise InvalidGemVersion.new('Please update your gem')
      end
    end

    # Uploading a gem file
    def push_gem(gem_file, options = {})
      ensure_ready!(:authorization)
      response = connection.post('gems', options.merge(
        :gem_file => gem_file
      ))

      ensure_successful_response!(response)
    end

    # List available gems
    def list(options = {})
      ensure_ready!(:authorization)
      response = connection.get('gems', options)
      ensure_successful_response!(response)
      response.body
    end

    # List versions for a gem
    def versions(name, options = {})
      ensure_ready!(:authorization)
      response = connection.get("gems/#{name}/versions", options)
      ensure_successful_response!(response)
      response.body
    end

    # Delete a gem version
    def yank_version(name, version, options = {})
      ensure_ready!(:authorization)
      response = connection.delete("gems/#{name}/versions/#{version}", options)
      ensure_successful_response!(response)
      response.body
    end

    # Get Authentication token via email/password
    def get_access_token(email, password, options = {})
      ensure_ready!
      response = connection.post('access_token', options.merge(
        :email => email, :password => password
      ))

      ensure_successful_response!(response)
      response.body['access_token']
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

    def ensure_successful_response!(response)
      unless response.success?
        raise(case response.status
          when 401 then Gemfury::Unauthorized
          else          Gemfury::Error
        end)
      end
    end
  end
end