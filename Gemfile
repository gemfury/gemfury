source "http://rubygems.org"

# Pull runtime dependencies from Gemspec
gemspec

# Lock rake
gem 'rake', '~> 10.0.0'

# Development dependencies
group :development do
  gem "webmock", "~> 1.8.7"
  gem "rspec", "~> 3.0"
  gem "multi_json"
  gem "json"

  # FakeFS 0.6+ doesn't support Ruby 1.8
  gem "fakefs", "< 0.6", :require => "fakefs/safe"

  # For testing on Ruby 1.8
  platforms :mri_18 do
    gem "system_timer"
  end
end