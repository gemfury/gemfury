module Gemfury
  module Auth

  private
    def authenticated?
      self.user_api_key && !self.user_api_key.empty?
    end

    def with_authentication(&block)
      raise Unauthorized unless authenticated?
      block.call
      # TODO: Catch 401 errors and wrap them w/ NotAuthenticated
    end
  end
end