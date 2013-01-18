source "http://rubygems.org"

# Pull runtime dependencies from Gemspec
gemspec

# Lock rake
gem 'rake', '~> 10.0.0'

# Development dependencies
group :development do
  gem "rspec", "~> 2.12.0"
  gem "webmock", "~> 1.8.7"
  gem "multi_json"
  gem "json"

  # For testing on Ruby 1.8
  platforms :mri_18 do
    gem "system_timer"
  end
end