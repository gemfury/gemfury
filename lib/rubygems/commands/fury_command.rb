require 'gemfury'
require 'gemfury/command'

class Gem::Commands::FuryCommand < Gem::Command
  def description
    'Push a private gem to your Gemfury account'
  end

  def arguments
    "GEM       built gem file to push"
  end

  def usage
    "#{program_name} GEM"
  end

  def initialize
    super 'fury', description
    add_option('-a', '--as USERNAME', 'Impersonate another account') do |value, options|
      options[:as] = value
    end
  end

  def execute
    opts = options.dup
    args = opts.delete(:args)
    Gemfury::Command::App.send(:dispatch, "push", args, opts, {})
  end
end
