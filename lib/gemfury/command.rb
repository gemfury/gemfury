require 'thor'
require 'yaml'
require 'launchy'
require 'highline'

module Gemfury
  class Command < Thor
    include Gemfury::Platform

    desc "version" ,"Check whether the gem is up-to-date"
    def version
      client.check_version
    end

    desc "push GEM" ,"upload a new version of a gem"
    def push(*gems)
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

  private
    def client
      options = {}

      # Load up the credentials
      config_path = File.expand_path('.gem/gemfury', home_directory)
      if File.exist?(config_path)
        config = YAML.load_file(config_path)
        options[:user_api_key] = config[:gemfury_api_key]
      end

      Gemfury::Client.new(options)
    end
  end
end