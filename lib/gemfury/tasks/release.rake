require 'rubygems/package'
require 'gemfury'
require 'gemfury/command'

namespace 'fury' do
  desc <<-desc
  Build gem and push it to Gemfury

  You can use a different account by setting AS=account
  desc
  task :release, :gemspec do |t, args|
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

      options = {}
      options[:as] = ENV['AS'] if ENV['AS']

      gemfile = File.basename(spec.cache_file)

      script = Gemfury::Command::App.new(['push', gemfile], options)
      script.invoke(:push, gemfile)
    end
  end
end

namespace 'gemfury' do
  task :release => 'fury:release'
end
