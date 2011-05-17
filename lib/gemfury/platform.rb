module Gemfury
  module Platform
    def home_directory
      on_windows? ? ENV['USERPROFILE'] : ENV['HOME']
    end

    def on_windows?
      RUBY_PLATFORM =~ /mswin32|mingw32/
    end

    def on_mac?
      RUBY_PLATFORM =~ /-darwin\d/
    end
  end
end