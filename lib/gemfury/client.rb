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

    # Get the information for the current account
    def account_info
      ensure_ready!(:authorization)
      response = connection.get('users/me')
      ensure_successful_response!(response)
      response.body
    end

    # Uploading a gem file
    def push_gem(gem_file, options = {})
      ensure_ready!(:authorization)

      # Generate upload link
      api2 = connection(:url => self.endpoint2)
      response = api2.post('uploads')
      ensure_successful_response!(response)

      # Upload to S3
      upload = response.body['upload']
      id, s3url = upload['id'], upload['blob']['put']
      response = s3_put_file(s3url, gem_file)
      ensure_successful_response!(response)

      # Notify Gemfury that the upload is ready
      options[:name] ||= File.basename(gem_file.path)
      response = api2.put("uploads/#{id}", options)
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
      url = "gems/#{escape(name)}/versions"
      response = connection.get(url, options)
      ensure_successful_response!(response)
      response.body
    end

    # Delete a gem version
    def yank_version(name, version, options = {})
      ensure_ready!(:authorization)
      url = "gems/#{escape(name)}/versions/#{escape(version)}"
      response = connection.delete(url, options)
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

    # List collaborators for this account
    def list_collaborators(options = {})
      ensure_ready!(:authorization)
      response = connection.get('collaborators', options)
      ensure_successful_response!(response)
      response.body
    end

    # Add a collaborator to the account
    def add_collaborator(login, options = {})
      ensure_ready!(:authorization)
      url = "collaborators/#{escape(login)}"
      response = connection.put(url, options)
      ensure_successful_response!(response)
    end

    # Remove a collaborator to the account
    def remove_collaborator(login, options = {})
      ensure_ready!(:authorization)
      url = "collaborators/#{escape(login)}"
      response = connection.delete(url, options)
      ensure_successful_response!(response)
    end

  private
    def escape(str)
      CGI.escape(str)
    end

    def connection(options = {})
      options = {
        :url => self.endpoint,
        :ssl => { :verify => false },
        :params => {},
        :headers => {
          :accept => 'application/json',
          :user_agent => user_agent,
          :x_gem_version => Gemfury::VERSION
        }
      }.merge(options)

      if self.user_api_key
        options[:headers][:authorization] = self.user_api_key
      end

      if self.account
        options[:params][:as] = self.account
      end

      Faraday.new(options) do |builder|
        builder.use Faraday::Request::MultipartWithFile
        builder.use Faraday::Request::Multipart
        builder.use Faraday::Request::UrlEncoded
        builder.use ParseJson
        builder.use Handle503
        builder.adapter :net_http
      end
    end

    def ensure_successful_response!(response)
      unless response.success?
        error = (response.body || {})['error'] || {}
        error_class = case response.status
        when 401 then Gemfury::Unauthorized
        when 403 then Gemfury::Forbidden
        when 404 then Gemfury::NotFound
        when 503 then Gemfury::TimeoutError
        when 400
          case error['type']
          when 'Forbidden'       then Gemfury::Forbidden
          when 'GemVersionError' then Gemfury::InvalidGemVersion
          when 'InvalidGemFile'  then Gemfury::CorruptGemFile
          when 'DupeVersion'     then Gemfury::DupeVersion
          else                        Gemfury::Error
          end
        else
          Gemfury::Error
        end

        raise(error_class, error['message'])
      end
    end

    def s3_put_file(uri, file)
      Faraday::Connection.new(uri) do |f|
        f.adapter :net_http
      end.put(uri, file, {
        :content_length => file.stat.size.to_s,
        :content_type => ''
      })
    end
  end
end