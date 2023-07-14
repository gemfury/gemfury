# frozen_string_literal: true

module Gemfury
  class Client
    module Filters
      private

      def ensure_ready!(*args)
        # Ensure authorization
        return unless args.include?(:authorization)
        raise Unauthorized unless authenticated?
      end

      def authenticated?
        user_api_key && !user_api_key.empty?
      end
    end
  end
end
