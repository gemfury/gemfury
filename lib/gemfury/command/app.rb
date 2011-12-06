class Gemfury::Command::App < Thor
  include Gemfury::Command::Authorization

  # Impersonation
  class_option :as, :desc => 'Access an account other than your own'

  map "-v" => :version
  desc "version" ,"Show Gemfury version", :hide => true
  def version
    shell.say Gemfury::VERSION
  end

  desc "whoami" ,"Show currently logged-in user", :hide => true
  def whoami
    if !has_credentials?
      shell.say %Q(You are not logged in), :green
    else
      with_checks_and_rescues do
        me = client.account_info['username']
        shell.say %Q(You are logged in as "#{me}"), :green
      end
    end
  end

  desc "push GEM", "Upload a new version of a gem"
  def push(*gems)
    with_checks_and_rescues do
      gem_files = gems.map do |g|
        File.exists?(g) ? File.new(g) : nil
      end.compact

      if gem_files.empty?
        shell.say "Problem: No valid gems specified", :red
        help(:push)
        return
      end

      # Let's get uploading
      gem_files.each do |gem_file|
        shell.say "Uploading #{File.basename(gem_file)}"
        client.push_gem(gem_file)
      end
    end
  end

  desc "list", "List your gems on Gemfury"
  def list
    with_checks_and_rescues do
      gems = client.list
      shell.say "\n*** GEMFURY GEMS ***\n\n"
      gems.each do |g|
        desc, version = g['name'], g.path('latest_version.version')
        desc << " (#{version ? version : 'beta'})"
        shell.say desc
      end
    end
  end

  desc "versions GEM", "List all the available gem versions"
  def versions(gem_name)
    with_checks_and_rescues do
      versions = client.versions(gem_name)
      shell.say "\n*** #{gem_name.capitalize} Versions ***\n\n"
      versions.each do |v|
        shell.say v['version']
      end
    end
  end

  desc "yank GEM", "Delete a gem version"
  method_options %w(version -v) => :required
  def yank(gem_name)
    with_checks_and_rescues do
      version = options[:version]
      client.yank_version(gem_name, version)
      shell.say "\n*** Yanked #{gem_name}-#{version} ***\n\n"
    end
  end

  desc "logout", "Remove Gemfury credentials"
  def logout
    if !has_credentials?
      shell.say "You are logged out"
    elsif shell.yes? "Are you sure you want to log out? [yN]"
      wipe_credentials!
      shell.say "You have been logged out"
    end
  end

  ### COLLABORATION MANAGEMENT ###
  map "sharing:add" => 'sharing_add'
  map "sharing:remove" => 'sharing_remove'

  desc "sharing", "List collaborators"
  def sharing
    with_checks_and_rescues do
      me = client.account_info['username']
      collaborators = client.list_collaborators
      if collaborators.empty?
        shell.say "You (#{me}) are the only collaborator", :green
      else
        shell.say %Q(\n*** Collaborators for "#{me}" ***\n), :green
        usernames = [me] + collaborators.map { |c| c['username'] }
        shell.say usernames.join("\n")
      end
      shell.say "\n"
    end
  end

  desc "sharing:add EMAIL", "Add a collaborator"
  def sharing_add(username)
    with_checks_and_rescues do
      client.add_collaborator(username)
      shell.say "Invited #{username} as a collaborator"
    end
  end

  desc "sharing:remove EMAIL", "Remove a collaborator"
  def sharing_remove(username)
    with_checks_and_rescues do
      client.remove_collaborator(username)
      shell.say "Removed #{username} as a collaborator"
    end
  end

private
  def client
    opts = {}
    opts[:user_api_key] = @user_api_key if @user_api_key
    opts[:account] = options[:as] if options[:as]
    Gemfury::Client.new(opts)
  end

  def with_checks_and_rescues(&block)
    with_authorization(&block)
  rescue Gemfury::InvalidGemVersion => e
    shell.say "You have a deprecated Gemfury gem", :red
    if shell.yes? "Would you like to update this gem now? [yN]"
      exec("gem update gemfury")
    else
      shell.say %q(No problem. You can also run "gem update gemfury")
    end
  rescue Gemfury::Forbidden => e
    shell.say "Oops! You're not allowed to access this", :red
  rescue Gemfury::NotFound => e
    shell.say "Oops! Doesn't look like this exists", :red
  rescue Exception => e
    shell.say "Oops! Something went wrong. Looking into it ASAP!", :red
  end
end