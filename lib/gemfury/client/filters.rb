module Gemfury
  class Client
    module Filters

    private
      def ensure_ready!(*args)
        # Ensure authorization
        if args.include?(:authorization)
          raise Unauthorized unless authenticated?
        end

        # Check version requirement
        ensure_gem_compatibility! if self.check_gem_version
      end

      def authenticated?
        self.user_api_key && !self.user_api_key.empty?
      end

      def ensure_gem_compatibility!
        response = connection.get('status/version')
        ensure_successful_response!(response)

        current = Gem::Version.new(Gemfury::VERSION)
        version = Gem::Requirement.new(response.body['version'])

        unless version.satisfied_by?(current)
          raise InvalidGemVersion.new('Please update your gem')
        end
      end
    end
  end
end