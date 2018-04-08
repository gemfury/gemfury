module Gemfury::Command::Authorization
  include Gemfury::Platform

  def wipe_credentials!
    FileUtils.rm(config_path, :force => true) # never raises exception
    each_netrc_host { |h| netrc_conf.delete(h) }
    netrc_conf.save
  end

  def has_credentials?
    !!netrc_conf[netrc_api_host] ||
    read_config_file.key?(:gemfury_api_key)
  end

private
  def with_authorization(&block)
    # Load up the credentials if user_api_key is not already set
    load_credentials! if @user_api_key.nil?

    # Attempt the operation and prompt user in case of
    # lack of authorization or a 401 response from the server
    begin
      prompt_credentials! if @user_api_key.nil?
      block.call
    rescue Gemfury::Unauthorized
      if acct = client.account
        shell.say %Q(Oops! You don't have access to "#{acct}"), :red
      else
        shell.say "Oops! Authentication failure.", :red
        @user_api_key = nil
        retry
      end
    end
  end

  def prompt_credentials!
    # Prompt credentials
    highline = HighLine.new
    highline.say 'Please enter your Gemfury credentials.'
    email = highline.ask('Email: ')
    passw = highline.ask('Password: ') { |q| q.echo = false }

    # Request and save the API access token
    if !email.empty? && !passw.empty?
      @user_api_key = client.get_access_token(email, passw)
      write_credentials!(email)
    end
  end

  def load_credentials!
    # Get credentials from ~/.netrc
    email, @user_api_key = netrc_conf[netrc_api_host]
    # Legacy loading from ~/.gem/gemfury
    @user_api_key ||= read_config_file[:gemfury_api_key]
  end

  def write_credentials!(email)
    each_netrc_host { |h| netrc_conf[h] = email, @user_api_key }
    netrc_conf.save
  end

  def read_config_file
    File.exist?(config_path) ? YAML.load_file(config_path) : {}
  end

  def netrc_conf
    @netrc ||= Netrc.read
  end

  def netrc_api_host
    URI.parse(client.endpoint).host
  end

  def each_netrc_host
    [:endpoint, :gitpoint, :pushpoint].each do |c|
      yield(URI.parse(client.send(c)).host)
    end
  end
end
