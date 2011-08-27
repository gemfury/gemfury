module Gemfury
  module Auth

  private
    def authenticated?
      self.user_api_key && !self.user_api_key.empty?
    end

    def ensure_authorization!
      raise Unauthorized unless authenticated?
    end
  end
end