module Gemfury::Command::Authorization
  include Gemfury::Platform

  def wipe_credentials!
    FileUtils.rm(config_path, :force => true) # never raises exception
  end

  def has_credentials?
    read_config_file.key?(:gemfury_api_key)
  end

private
  def with_authorization(&block)
    # Load up the credentials
    load_credentials!

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
      write_credentials!
    end
  end

  def load_credentials!
    conf = read_config_file
    @user_api_key = conf[:gemfury_api_key] if conf[:gemfury_api_key]
  end

  def write_credentials!
    config = read_config_file.merge(:gemfury_api_key => @user_api_key)
    FileUtils.mkdir_p(File.dirname(config_path))
    File.open(config_path, 'w') { |f| f.write(YAML.dump(config)) }
  end

  def read_config_file
    File.exist?(config_path) ? YAML.load_file(config_path) : {}
  end
end