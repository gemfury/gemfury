require 'progressbar'
require 'delegate'

class Gemfury::Command::App < Thor
  include Gemfury::Command::Authorization
  UserAgent = "Gemfury CLI #{Gemfury::VERSION}".freeze
  PackageExtensions = %w(gem egg tar.gz tgz nupkg)

  # Impersonation
  class_option :as, :desc => 'Access an account other than your own'
  class_option :api_token, :desc => 'API token to use for commands'

  # Make sure we retain the default exit behaviour of 0 even on argument errors
  def self.exit_on_failure?; false; end

  map "-v" => :version
  desc "version", "Show Gemfury version", :hide => true
  def version
    shell.say Gemfury::VERSION
  end

  ### PACKAGE MANAGEMENT ###
  option :public, :type => :boolean, :desc => "Create as public package"
  option :quiet, :type => :boolean, :aliases => "-q", :desc => "Do not show progress bar", :default => false
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

      va = [ %w{ name kind version privacy } ]
      gems.each do |g|
        va << [ g['name'], g['language'],
                g.dig('latest_version', 'version') || 'beta',
                g['private'] ? 'private' : 'public ' ]
      end

      shell.print_table(va)
    end
  end

  desc "versions NAME", "List all the package versions"
  def versions(gem_name)
    with_checks_and_rescues do
      versions = client.versions(gem_name)
      shell.say "\n*** #{gem_name.capitalize} Versions ***\n\n"

      va = []
      va = [ %w{ version uploaded_by uploaded } ]
      versions.each do |v|
        uploaded = time_ago(Time.parse(v['created_at']).getlocal)
        va << [ v['version'], v['created_by']['name'], uploaded ]
      end

      shell.print_table(va)
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

  ### AUTHENTICATION ###
  desc "logout", "Remove Gemfury credentials"
  def logout
    if !has_credentials?
      shell.say "You are logged out"
    elsif shell.yes? "Are you sure you want to log out? [yN]"
      with_checks_and_rescues { client.logout }
      wipe_credentials!
      shell.say "You have been logged out"
    end
  end

  desc "login", "Save Gemfury credentials"
  def login
    with_checks_and_rescues do
      me = client.account_info['name']
      shell.say %Q(You are logged in as "#{me}"), :green
    end
  end

  desc "whoami", "Show current user"
  def whoami
    has_credentials? ? self.login : begin
      shell.say %Q(You are not logged in), :green
    end
  end

  desc "accounts", "Show info about your Gemfury accounts"
  def accounts
    with_checks_and_rescues do
      accounts = client.accounts

      va = [ %w{ name kind permission } ]
      accounts.each do |a|
        va << [ a['name'], a['type'], a['viewer_permission'].downcase ]
      end

      shell.print_table(va)
    end
  end

  ### COLLABORATION MANAGEMENT ###
  map "sharing:add" => 'sharing_add'
  map "sharing:remove" => 'sharing_remove'

  desc "sharing", "List collaborators"
  def sharing
    with_checks_and_rescues do
      account_info = client.account_info
      me = account_info['username']

      collaborators = client.list_collaborators
      if collaborators.empty?
        shell.say %Q(You (#{me}) are the only collaborator\n), :green
      else
        shell.say %Q(\n*** Collaborators for "#{me}" ***\n), :green

        va = [ %w{ username permission } ]

        if account_info['type'] == 'user'
          va << [ me, 'owner' ]
        end

        collaborators.each { |c| va << [ c['username'], c['permission'] ] }

        shell.print_table(va)
      end
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

  ### GIT REPOSITORY MANAGEMENT ###
  map "git:list"    => 'git_list'
  map "git:reset"   => 'git_reset'
  map "git:rename"  => 'git_rename'
  map "git:rebuild" => 'git_rebuild'

  desc "git:list", "List Git repositories"
  def git_list
    with_checks_and_rescues do
      repos = client.git_repos['repos']
      shell.say "\n*** GEMFURY GIT REPOS ***\n\n"
      names = repos.map { |r| r['name'] }
      names.sort.each { |n| shell.say(n) }
    end
  end

  desc "git:rename", "Rename a Git repository"
  def git_rename(repo, new_name)
    with_checks_and_rescues do
      client.git_update(repo, :repo => { :name => new_name })
      shell.say "Renamed #{repo} repository to #{new_name}\n"
    end
  end

  desc "git:reset", "Remove a Git repository"
  def git_reset(repo)
    with_checks_and_rescues do
      client.git_reset(repo)
      shell.say "\n*** Yanked #{repo} repository ***\n\n"
    end
  end

  desc "git:rebuild", "Rebuild a Git repository"
  method_options %w(revision -r) => :string
  def git_rebuild(repo)
    with_checks_and_rescues do
      params = { :revision => options[:revision] }
      shell.say "\n*** Rebuilding #{repo} repository ***\n\n"
      shell.say client.git_rebuild(repo, :build => params)
    end
  end

  ### GIT REPOSITORY BUILD CONFIG ###
  map 'git:config'       => 'git_config'
  map 'git:config:set'   => 'git_config_set'
  map 'git:config:unset' => 'git_config_unset'

  desc "git:config", "List Git repository's build environment"
  def git_config(repo)
    with_checks_and_rescues do
      vars = client.git_config(repo)['config_vars']
      shell.say "*** #{repo} build config ***\n"
      shell.print_table(vars.map { |kv|
        ["#{kv[0]}:", kv[1]]
      })
    end
  end

  desc "git:config:set", "Update Git repository's build environment"
  def git_config_set(repo, *vars)
    with_checks_and_rescues do
      updates = Hash[vars.map { |v| v.split("=", 2) }]
      client.git_config_update(repo, updates)
      shell.say "Updated #{repo} build config"
    end
  end

  desc "git:config:unset", "Remove variables from Git repository's build environment"
  def git_config_unset(repo, *vars)
    with_checks_and_rescues do
      updates = Hash[vars.map { |v| [v, nil] }]
      client.git_config_update(repo, updates)
      shell.say "Updated #{repo} build config"
    end
  end

private
  def client
    opts = {}
    opts[:user_api_key] = @user_api_key if @user_api_key
    opts[:account] = options[:as] if options[:as]
    client = Gemfury::Client.new(opts)
    client.user_agent = UserAgent
    return client
  end

  def with_checks_and_rescues(&block)
    @user_api_key = options[:api_token] if options[:api_token]
    with_authorization(&block)
  rescue Gemfury::InvalidGemVersion => e
    shell.say "You have a deprecated Gemfury client", :red
    if shell.yes? "Would you like to update it now? [yN]"
      exec("gem update gemfury")
    else
      shell.say %q(No problem. You can also run "gem update gemfury")
    end
  rescue Gemfury::Conflict => e
    die!("Oops! Locked for another user. Try again later.", e)
  rescue Gemfury::Forbidden => e
    die!("Oops! You're not allowed to access this", e)
  rescue Gemfury::NotFound => e
    die!("Oops! Doesn't look like this exists", e)
  rescue Gemfury::Error => e
    die!("Oops! %s" % e.message, e)
  rescue StandardError => e
    die!("Oops! Something went wrong. Please contact support.", e)
  end

  def push_files(command, gem_paths)
    files = gem_paths.map do |g|
      g.is_a?(String) ? File.new(g) : g rescue nil
    end.compact

    if !options[:quiet] && !shell.mute? && $stdout.tty?
      files = files.map { |g| ProgressIO.new(g) }
    end

    if files.empty?
      die!("Problem: No valid packages found", nil, command)
    end

    push_options = { }
    unless options[:public].nil?
      push_options[:public] = options[:public]
    end

    error_ex = nil

    files.each do |file|
      show_bar = file.is_a?(ProgressIO) && file.show_bar?
      title = "Uploading #{File.basename(file.path)} "

      begin
        if show_bar
          begin
            client.push_gem(file, push_options)
          ensure
            shell.say "\e[A\e[0K", nil, false
            shell.say title
          end
        else
          shell.say title
          client.push_gem(file, push_options)
        end

        shell.say "- done"
      rescue Gemfury::CorruptGemFile => e
        shell.say "- problem processing this package", :red
        error_ex = e
      rescue Gemfury::DupeVersion => e
        shell.say "- this version already exists", :red
        error_ex = e
      rescue Gemfury::TimeoutError, Errno::EPIPE => e
        shell.say "- this file is too much to handle", :red
        shell.say "  Visit http://www.gemfury.com/large-package for more info"
        error_ex = e
      rescue => e
        shell.say "- oops", :red
        error_ex = e
      end
    end

    unless error_ex.nil?
      die!('There was a problem uploading at least 1 package', error_ex)
    end
  end

  C50K = 50000

  class ProgressIO < SimpleDelegator
    attr_reader :content_type, :original_filename, :local_path

    def initialize(filename_or_io, content_type = 'application/octet-stream', fname = nil)
      io = filename_or_io
      local_path = ''

      if io.respond_to? :read
        local_path = filename_or_io.respond_to?(:path) ? filename_or_io.path : 'local.path'
      else
        io = File.open(filename_or_io)
        local_path = filename_or_io
      end

      fname ||= local_path

      @content_type = content_type
      @original_filename = File.basename(fname)
      @local_path = local_path

      if io.respond_to? :size
        filesize = io.size
      else
        filesize = io.stat.size
      end

      if filesize > C50K
        title = 'Uploading %s ' % File.basename(fname)
        @bar = ProgressBar.create(:title => title, :total => filesize)
      else
        @bar = nil
      end

      super(io)
    end

    def show_bar?
      @bar != nil
    end

    def read(length)
      buf = __getobj__.read(length)
      unless @bar.nil? || buf.nil?
        @bar.progress += buf.bytesize
      end

      buf
    end
  end

  def die!(msg, err = nil, command = nil)
    shell.say msg, :red
    help(command) if command
    shell.say %Q(#{err.class.name}: #{err}\n#{err.backtrace.join("\n")}) if err && ENV['DEBUG']
    exit(1)
  end

  def time_ago(tm)
    ago = tm.strftime('%F %R')

    in_secs = Time.now - tm
    if in_secs < 60
      ago += ' (~ %ds ago)' % in_secs
    elsif in_secs < 3600
      ago += ' (~ %sm ago)' % (in_secs / 60).floor
    elsif in_secs < (3600 * 24)
      ago += ' (~ %sh ago)' % (in_secs / 3600).floor
    end

    ago
  end
end
