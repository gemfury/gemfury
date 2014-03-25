class Gemfury::Command::App < Thor
  include Gemfury::Command::Authorization
  PackageExtensions = %w(gem egg tar.gz tgz)

  # Impersonation
  class_option :as, :desc => 'Access an account other than your own'

  map "-v" => :version
  desc "version", "Show Gemfury version", :hide => true
  def version
    shell.say Gemfury::VERSION
  end

  desc "whoami", "Show current user"
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

  desc "push FILE", "Upload a new version of a package"
  def push(*gems)
    with_checks_and_rescues do
      push_files(:push, gems)
    end
  end

  desc "list", "List your packages"
  def list
    with_checks_and_rescues do
      gems = client.list
      shell.say "\n*** GEMFURY PACKAGES ***\n\n"
      gems.each do |g|
        desc, version = g['name'], g.path('latest_version.version')
        desc << " (#{version ? version : 'beta'})"
        shell.say desc
      end
    end
  end

  desc "versions NAME", "List all the package versions"
  def versions(gem_name)
    with_checks_and_rescues do
      versions = client.versions(gem_name)
      shell.say "\n*** #{gem_name.capitalize} Versions ***\n\n"
      versions.each do |v|
        shell.say v['version']
      end
    end
  end

  desc "yank NAME", "Delete a package version"
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

  ### MIGRATION (Pushing directories) ###
  desc "migrate DIR", "Upload all packages within a directory"
  def migrate(*paths)
    with_checks_and_rescues do
      gem_paths = Dir.glob(paths.map do |p|
        if File.directory?(p)
          PackageExtensions.map { |ext| "#{p}/**/*.#{ext}" }
        elsif File.file?(p)
          p
        else
          nil
        end
      end.flatten.compact)

      if gem_paths.empty?
        die!("Problem: No valid packages found", nil, :migrate)
      else
        shell.say "Found the following packages:"
        gem_paths.each { |p| shell.say "  #{File.basename(p)}" }
        if shell.yes? "Upload these files to Gemfury? [yN]", :green
          push_files(:migrate, gem_paths)
        end
      end
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
    shell.say "You have a deprecated Gemfury client", :red
    if shell.yes? "Would you like to update it now? [yN]"
      exec("gem update gemfury")
    else
      shell.say %q(No problem. You can also run "gem update gemfury")
    end
  rescue Gemfury::Forbidden => e
    die!("Oops! You're not allowed to access this", e)
  rescue Gemfury::NotFound => e
    die!("Oops! Doesn't look like this exists", e)
  rescue StandardError => e
    die!("Oops! Something went wrong. Please contact support.", e)
  end

  def push_files(command, gem_paths)
    files = gem_paths.map do |g|
      g.is_a?(String) ? File.new(g) : g rescue nil
    end.compact

    if files.empty?
      die!("Problem: No valid packages found", nil, command)
    end

    # Let's get uploading
    files.each do |file|
      begin
        shell.say "Uploading #{File.basename(file.path)} "
        client.push_gem(file)
        shell.say "- done"
      rescue Gemfury::CorruptGemFile
        shell.say "- problem processing this package", :red
      rescue Gemfury::DupeVersion
        shell.say "- this version already exists", :red
      rescue Gemfury::TimeoutError, Errno::EPIPE
        shell.say "- this file is too much to handle", :red
        shell.say "  Visit http://www.gemfury.com/large-package for more info"
      rescue => e
        shell.say "- oops", :red
        raise e
      end
    end
  end

  def die!(msg, err = nil, command = nil)
    shell.say msg, :red
    help(command) if command
    shell.say %Q(#{err.class.name}: #{err}\n#{err.backtrace.join("\n")}) if err && ENV['DEBUG']
    exit(1)
  end
end