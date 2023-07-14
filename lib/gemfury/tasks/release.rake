# frozen_string_literal: true

require 'rubygems/package'
require 'gemfury'
require 'gemfury/command'

namespace 'fury' do
  desc 'Build gem and push it to Gemfury'
  task :release, [:gemspec, :as] do |_t, args|
    gemspec = args[:gemspec] || FileList["#{Dir.pwd}/*.gemspec"][0]

    if gemspec.nil? || !File.exist?(gemspec)
      puts 'No gemspec found'
    else
      puts "Building #{File.basename(gemspec)}"
      spec = Gem::Specification.load(gemspec)

      if Gem::Package.respond_to?(:build)
        Gem::Package.build(spec)
      else
        require 'rubygems/builder'
        Gem::Builder.new(spec).build
      end

      gemfile = File.basename(spec.cache_file)

      params = ['push', gemfile, '--no_warnings']
      params << "--as=#{args[:as]}" if args[:as]

      Gemfury::Command::App.start(params)
    end
  end
end

namespace 'gemfury' do
  task release: 'fury:release'
end
