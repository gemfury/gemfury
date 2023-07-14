# frozen_string_literal: true

module Gemfury
  class Client
    include Gemfury::Client::Filters
    include Gemfury::Configuration

    # Creates a new API
    # @param options [Hash] values for attributes described in {Gemfury::Configuration}
    def initialize(options = {})
      options = Gemfury.options.merge(options)
      Gemfury::VALID_OPTIONS_KEYS.each do |key|
        send("#{key}=", options[key])
      end
    end

    # Get the information for the current account
    # @return [Hash]
    def account_info
      ensure_ready!(:authorization)
      response = connection.get('users/me')
      checked_response_body(response)
    end

    # Get the information for the all accounts that this account has some level of access to
    # @return [Array<Hash>]
    def accounts
      ensure_ready!(:authorization)
      response = connection.get('accounts')
      checked_response_body(response)
    end

    # Upload an artifact file
    # @param file [String] the filename to upload
    # @param options [Hash] Faraday client options
    # @return [Hash]
    def push_gem(file, options = {})
      ensure_ready!(:authorization)
      push_api = connection(url: pushpoint)
      response = push_api.post('uploads', options.merge(file: file))
      checked_response_body(response)
    end

    # List available artifacts
    # @param options [Hash] Faraday client options
    # @return [Array<Hash>]
    def list(options = {})
      ensure_ready!(:authorization)
      response = connection.get('gems', options)
      checked_response_body(response)
    end

    # List versions for an artifact
    # @param name [String] the name of the artifact
    # @param options [Hash] Faraday client options
    # @return [Array<Hash>]
    def versions(name, options = {})
      ensure_ready!(:authorization)
      url = "gems/#{escape(name)}/versions"
      response = connection.get(url, options)
      checked_response_body(response)
    end

    # Delete an artifact version
    # @param name [String] the name of the artifact
    # @param version [String] the version of the artifact
    # @param options [Hash] Faraday client options
    # @return [Hash]
    def yank_version(name, version, options = {})
      ensure_ready!(:authorization)
      url = "gems/#{escape(name)}/versions/#{escape(version)}"
      response = connection.delete(url, options)
      checked_response_body(response)
    end

    # LEGACY: Authentication token via email/password
    def get_access_token(*args)
      login(*args)['token']
    end

    # Get authentication info via email/password
    # @param email [String] the account email address
    # @param password [String] the account password
    # @param opts [Hash] Faraday client options
    # @return [Hash]
    def login(email, password, opts = {})
      ensure_ready!
      opts = opts.merge(email: email, password: password)
      checked_response_body(connection.post('login', opts))
    end

    # Invalidate session token
    # @return [Hash]
    def logout
      ensure_ready!(:authorization)
      response = connection.post('logout')
      checked_response_body(response)
    end

    # List collaborators for this account
    # @param options [Hash] Faraday client options
    # @return [Array<Hash>]
    def list_collaborators(options = {})
      ensure_ready!(:authorization)
      response = connection.get('collaborators', options)
      checked_response_body(response)
    end

    # Add a collaborator to the account
    # @param options [Hash] Faraday client options
    # @return [Hash]
    def add_collaborator(login, options = {})
      ensure_ready!(:authorization)
      url = "collaborators/#{escape(login)}"
      response = connection.put(url, options)
      checked_response_body(response)
    end

    # Remove a collaborator to the account
    # @param login [String] the account login
    # @param options [Hash] Faraday client options
    # @return [Hash]
    def remove_collaborator(login, options = {})
      ensure_ready!(:authorization)
      url = "collaborators/#{escape(login)}"
      response = connection.delete(url, options)
      checked_response_body(response)
    end

    # List Git repos for this account
    # @param options [Hash] Faraday client options
    # @return [Hash]
    def git_repos(options = {})
      ensure_ready!(:authorization)
      response = connection.get(git_repo_path, options)
      checked_response_body(response)
    end

    # Update repository name and settings
    # @param repo [String] the repo name
    # @param options [Hash] Faraday client options
    # @return [Hash]
    def git_update(repo, options = {})
      ensure_ready!(:authorization)
      response = connection.patch(git_repo_path(repo), options)
      checked_response_body(response)
    end

    # Reset repository to initial state
    # @param repo [String] the repo name
    # @param options [Hash] Faraday client options
    # @return [Hash]
    def git_reset(repo, options = {})
      ensure_ready!(:authorization)
      response = connection.delete(git_repo_path(repo), options)
      checked_response_body(response)
    end

    # Rebuild Git repository package
    # @param repo [String] the repo name
    # @param options [Hash] Faraday client options
    # @return [Hash]
    def git_rebuild(repo, options = {})
      ensure_ready!(:authorization)
      url = "#{git_repo_path(repo)}/builds"
      api = connection(api_format: :text)
      checked_response_body(api.post(url, options))
    end

    # List Git repo's build configuration
    # @param repo [String] the repo name
    # @param options [Hash] Faraday client options
    # @return [Hash]
    def git_config(repo, options = {})
      ensure_ready!(:authorization)
      path = "#{git_repo_path(repo)}/config-vars"
      response = connection.get(path, options)
      checked_response_body(response)
    end

    # Update Git repo's build configuration
    # @param repo [String] the repo name
    # @param updates [Hash] Updates to configuration
    # @param options [Hash] Faraday client options
    # @return [Hash]
    def git_config_update(repo, updates, options = {})
      ensure_ready!(:authorization)
      path = "#{git_repo_path(repo)}/config-vars"
      opts = options.merge(config_vars: updates)
      response = connection.patch(path, opts)
      checked_response_body(response)
    end

    private

    def escape(str)
      CGI.escape(str)
    end

    def git_repo_path(*args)
      rest = args.map { |a| escape(a) }
      ['git/repos', account || 'me'].concat(rest).join('/')
    end

    def connection(options = {})
      # The 'Accept' HTTP header for API versioning
      http_accept = begin
        v = options.delete(:api_version) || api_version
        f = options.delete(:api_format)  || :json
        "application/vnd.fury.v#{v.to_i}+#{f}"
      end

      # Faraday client options
      options = {
        url: endpoint,
        params: {},
        headers: {
          accept: http_accept,
          user_agent: user_agent,
          x_gem_version: Gemfury::VERSION
        }.merge(options.delete(:headers) || {})
      }.merge(options)

      options[:headers][:authorization] = user_api_key if user_api_key

      options[:params][:as] = account if account

      Faraday.new(options) do |builder|
        builder.use Faraday::Request::MultipartWithFile
        builder.use Faraday::Multipart::Middleware
        builder.use Faraday::Request::UrlEncoded
        builder.use ParseJson
        builder.use Handle503
        builder.adapter :fury_http
      end
    end

    def checked_response_body(response)
      return response.body if response.success?

      error = (response.body || {})['error'] || {}
      error_class = case error['type']
                    when 'Forbidden'       then Gemfury::Forbidden
                    when 'GemVersionError' then Gemfury::InvalidGemVersion
                    when 'InvalidGemFile'  then Gemfury::CorruptGemFile
                    when 'DupeVersion'     then Gemfury::DupeVersion
                    else
                      case response.status
                      when 401 then Gemfury::Unauthorized
                      when 403 then Gemfury::Forbidden
                      when 404 then Gemfury::NotFound
                      when 409 then Gemfury::Conflict
                      when 503 then Gemfury::TimeoutError
                      else          Gemfury::Error
                      end
                    end

      raise(error_class, error['message'])
    end

    def s3_put_file(uri, file)
      Faraday::Connection.new(uri) do |f|
        f.adapter :net_http
      end.put(uri, file, {
                content_length: file.stat.size.to_s,
                content_type: ''
              })
    end
  end
end
