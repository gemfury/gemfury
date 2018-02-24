require 'rubygems/package'
require 'gemfury'
require 'gemfury/command'

namespace 'fury' do
  desc "Build gem and push it to Gemfury"
  task :release, [:gemspec, :as] do |t, args|
    gemspec = args[:gemspec] ||
              FileList["#{Dir.pwd}/*.gemspec"][0]

    if gemspec.nil? || !File.exist?(gemspec)
      puts "No gemspec found"
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

      params = ['push', gemfile]

      if args[:as]
        as = args[:as]
      elsif ENV.include?('FURY_AS')
        as = ENV['FURY_AS']
      else
        as = nil
      end

      unless as.nil?
        params << "--as=%s" % as
      end

      Gemfury::Command::App.start(params)
    end
  end
end

namespace 'gemfury' do
  task :release => 'fury:release'
end
