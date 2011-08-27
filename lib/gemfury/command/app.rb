class Gemfury::Command::App < Thor
  include Gemfury::Command::Authorization

  desc "push GEM" ,"Upload a new version of a gem"
  def push(*gems)
    with_authorization do
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

  desc "list" ,"List your gems on Gemfury"
  def list
    with_authorization do
      gems = client.list
      shell.say "\n*** GEMFURY GEMS ***\n\n"
      gems.each do |g|
        desc, version = g['name'], g.path('latest_version.version')
        desc << " (#{version})" if version
        shell.say desc
      end
    end
  end

  desc "versions GEM" ,"List all the available gem versions"
  def versions(gem_name)
    with_authorization do
      versions = client.versions(gem_name)
      shell.say "\n*** #{gem_name.capitalize} Versions ***\n\n"
      versions.each do |v|
        shell.say v['version']
      end
    end
  end

private
  def client
    options = {}
    options[:user_api_key] = @user_api_key if @user_api_key
    Gemfury::Client.new(options)
  end
end