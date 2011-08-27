class Gemfury::Command::App < Thor
  include Gemfury::Command::Authorization

  desc "version" ,"Check whether the gem is up-to-date"
  def version
    client.check_version
  end

  desc "push GEM" ,"upload a new version of a gem"
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

private
  def client
    options = {}
    options[:user_api_key] = @user_api_key if @user_api_key
    Gemfury::Client.new(options)
  end
end