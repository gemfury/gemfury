# frozen_string_literal: true

$LOAD_PATH.unshift 'lib'
require 'gemfury/version'

Gem::Specification.new do |s|
  s.name              = 'gemfury'
  s.version           = ENV['BUILD_VERSION'] || Gemfury::VERSION
  s.summary           = 'Hosted repo for your public and private packages'
  s.homepage          = 'https://gemfury.com'
  s.email             = 'hello@gemfury.com'
  s.authors           = ['Michael Rykov']
  s.license           = 'MIT'

  s.executables       = %w[gemfury fury]
  s.files             = %w[README.md] +
                        Dir.glob('bin/**/*') +
                        Dir.glob('lib/**/*')

  # We will match the oldest dependency
  s.required_ruby_version = '>= 2.6.0'

  # NOTE: we clamp the upper bound requirement to be below the prerelease
  # version because a requirement like '< 1.1.0' will still allow '1.1.0.pre'
  # to be installed and loaded. And we have seen this cause issues.

  s.add_dependency    'faraday', '>= 2.0.0', '< 3.0.0.pre'
  s.add_dependency    'faraday-multipart', '>= 1.0.0', '< 2.0.0.pre'
  s.add_dependency    'highline', '>= 1.6.0', '< 2.1.0.pre'
  s.add_dependency    'multi_json', '~> 1.10'
  s.add_dependency    'netrc', '>= 0.10.0', '< 0.12.0.pre'
  s.add_dependency    'progressbar', '>= 1.10.1', '< 2.0.0.pre'
  s.add_dependency    'thor', '>= 0.14.0', '< 1.1.0.pre'

  s.description = <<~DESCRIPTION
    Hosted repo for your public and private packages at https://gemfury.com
  DESCRIPTION

  s.post_install_message = <<~POSTINSTALL
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
  s.metadata['rubygems_mfa_required'] = 'true'
end
