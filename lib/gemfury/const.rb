module Gemfury
  module Const
    class << self
      def host
        'www.gemfury.com'
        #'localhost:3000'
      end

      def welcome
        "Welcome to Gemfury!\nPlease complete the following information"
      end

      def email_error
        "Invalid email address. Please try again."
      end

      def email_regex
        return @email_regex if @email_regex
        email_name_regex  = '[A-Z0-9_\.%\+\-\']+'
        domain_head_regex = '(?:[A-Z0-9\-]+\.)+'
        domain_tld_regex  = '(?:[A-Z]{2,4}|museum|travel)'
        @email_regex = /^#{email_name_regex}@#{domain_head_regex}#{domain_tld_regex}$/i
      end
    end
  end
end
