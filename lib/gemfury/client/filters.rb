module Gemfury
  class Client
    module Filters

    private
      def ensure_ready!(*args)
        # Ensure authorization
        if args.include?(:authorization)
          raise Unauthorized unless authenticated?
        end
      end

      def authenticated?
        self.user_api_key && !self.user_api_key.empty?
      end
    end
  end
end