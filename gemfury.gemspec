$LOAD_PATH.unshift 'lib'
require 'gemfury/version'

Gem::Specification.new do |s|
  s.name              = "gemfury"
  s.date              = Time.now.strftime('%Y-%m-%d')
  s.version           = ENV["BUILD_VERSION"] || Gemfury::VERSION
  s.summary           = "Hosted repo for your public and private packages"
  s.homepage          = "https://gemfury.com"
  s.email             = "hello@gemfury.com"
  s.authors           = [ "Michael Rykov" ]
  s.license           = 'MIT'

  s.executables       = %w(gemfury fury)
  s.files             = %w(README.md) +
                        Dir.glob("bin/**/*") +
                        Dir.glob("lib/**/*")

  s.add_dependency    "multi_json", "~> 1.10"
  s.add_dependency    "thor", ">= 0.14.0", "< 1.1.0"
  s.add_dependency    "netrc", ">= 0.10.0", "< 0.12.0.pre"
  s.add_dependency    "faraday", ">= 0.9.0", "< 1.1"
  s.add_dependency    "highline", ">= 1.6.0", "< 2.1.0.pre"
  s.add_dependency    "progressbar", ">= 1.10.1"

  s.description = <<DESCRIPTION
Hosted repo for your public and private packages at https://gemfury.com
DESCRIPTION

  s.post_install_message =<<POSTINSTALL
************************************************************************

  Upload your first package to start using Gemfury:
  fury push my-package-1.0.0.gem

  If you have a directory with packages, you can use:
  fury migrate ./path/to/codez

  Find out what else you can do:
  fury help

  Follow @gemfury on Twitter for announcements, updates, and news.
  https://twitter.com/gemfury

************************************************************************
POSTINSTALL
end
