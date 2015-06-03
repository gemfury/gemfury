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
      checked_response_body(response)
    end

    # Uploading a gem file
    def push_gem(gem_file, options = {})
      ensure_ready!(:authorization)

      # Generate upload link
      api2 = connection(:api_version => 2)
      response = api2.post('uploads')
      checked_response_body(response)

      # Upload to S3
      upload = response.body['upload']
      id, s3url = upload['id'], upload['blob']['put']
      response = s3_put_file(s3url, gem_file)
      checked_response_body(response)

      # Notify Gemfury that the upload is ready
      options[:name] ||= File.basename(gem_file.path)
      response = api2.put("uploads/#{id}", options)
      checked_response_body(response)
    end

    # List available gems
    def list(options = {})
      ensure_ready!(:authorization)
      response = connection.get('gems', options)
      checked_response_body(response)
    end

    # List versions for a gem
    def versions(name, options = {})
      ensure_ready!(:authorization)
      url = "gems/#{escape(name)}/versions"
      response = connection.get(url, options)
      checked_response_body(response)
    end

    # Delete a gem version
    def yank_version(name, version, options = {})
      ensure_ready!(:authorization)
      url = "gems/#{escape(name)}/versions/#{escape(version)}"
      response = connection.delete(url, options)
      checked_response_body(response)
    end

    # LEGACY: Authentication token via email/password
    def get_access_token(*args)
      login(*args)['access_token']
    end

    # Get authentication info via email/password
    def login(email, password, opts = {})
      ensure_ready!
      opts = opts.merge(:email => email, :password => password)
      checked_response_body(connection.post('access_token', opts))
    end

    # List collaborators for this account
    def list_collaborators(options = {})
      ensure_ready!(:authorization)
      response = connection.get('collaborators', options)
      checked_response_body(response)
    end

    # Add a collaborator to the account
    def add_collaborator(login, options = {})
      ensure_ready!(:authorization)
      url = "collaborators/#{escape(login)}"
      response = connection.put(url, options)
      checked_response_body(response)
    end

    # Remove a collaborator to the account
    def remove_collaborator(login, options = {})
      ensure_ready!(:authorization)
      url = "collaborators/#{escape(login)}"
      response = connection.delete(url, options)
      checked_response_body(response)
    end

    # List Git repos for this account
    def git_repos(options = {})
      ensure_ready!(:authorization)
      response = connection.get(git_repo_path, options)
      checked_response_body(response)
    end

    # Update repository name and settings
    def git_update(repo, options = {})
      ensure_ready!(:authorization)
      response = connection.patch(git_repo_path(repo), options)
      checked_response_body(response)
    end

    # Reset repository to initial state
    def git_reset(repo, options = {})
      ensure_ready!(:authorization)
      response = connection.delete(git_repo_path(repo), options)
      checked_response_body(response)
    end

    # Rebuild Git repository package
    def git_rebuild(repo, options = {})
      ensure_ready!(:authorization)
      url = "#{git_repo_path(repo)}/builds"
      api = connection(:api_format => :text)
      checked_response_body(api.post(url, options))
    end

  private
    def escape(str)
      CGI.escape(str)
    end

    def git_repo_path(*args)
      rest = args.map { |a| escape(a) }
      ['git/repos', self.account || 'me'].concat(rest).join('/')
    end

    def connection(options = {})
      # The 'Accept' HTTP header for API versioning
      http_accept = begin
        v = options.delete(:api_version) || self.api_version
        f = options.delete(:api_format)  || :json
        "application/vnd.fury.v#{v.to_i}+#{f}"
      end

      # Faraday client options
      options = {
        :url => self.endpoint,
        :params => {},
        :headers => {
          :accept => http_accept,
          :user_agent => self.user_agent,
          :x_gem_version => Gemfury::VERSION,
        }.merge(options.delete(:headers) || {})
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
        builder.adapter :fury_http
      end
    end

    def checked_response_body(response)
      if response.success?
        return response.body
      else
        error = (response.body || {})['error'] || {}
        error_class = case response.status
        when 401 then Gemfury::Unauthorized
        when 403 then Gemfury::Forbidden
        when 404 then Gemfury::NotFound
        when 409 then Gemfury::Conflict
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