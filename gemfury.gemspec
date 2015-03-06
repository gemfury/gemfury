$LOAD_PATH.unshift 'lib'
require 'gemfury/version'

Gem::Specification.new do |s|
  s.name              = "gemfury"
  s.version           = Gemfury::VERSION
  s.date              = Time.now.strftime('%Y-%m-%d')
  s.summary           = "Cloud Gem Server for your private RubyGems"
  s.homepage          = "http://www.gemfury.com"
  s.email             = "mrykov@gmail.com"
  s.authors           = [ "Michael Rykov" ]
  s.license           = 'MIT'
  s.has_rdoc          = false

  s.executables       = %w(gemfury fury)
  s.files             = %w(README.md) +
                        Dir.glob("bin/**/*") +
                        Dir.glob("lib/**/*")

  s.add_dependency    "highline", "~> 1.6.0"
  s.add_dependency    "netrc", "~> 0.10.0"
  s.add_dependency    "multi_json", "~> 1.0"
  s.add_dependency    "thor", ">= 0.14.0", "< 1.0.0.pre"
  s.add_dependency    "faraday", ">= 0.9.0", "< 0.10.0.pre"

  s.description = <<DESCRIPTION
Cloud Gem Server for your private RubyGems at http://gemfury.com
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
