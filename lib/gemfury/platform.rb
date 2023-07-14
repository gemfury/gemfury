# frozen_string_literal: true

module Gemfury
  module Platform
    def home_directory
      on_windows? ? ENV.fetch('USERPROFILE', nil) : Dir.home
    end

    def config_path
      File.expand_path('.gem/gemfury', home_directory)
    end

    def on_windows?
      RUBY_PLATFORM =~ /mswin32|mingw32/
    end

    def on_mac?
      RUBY_PLATFORM =~ /-darwin\d/
    end
  end
end
