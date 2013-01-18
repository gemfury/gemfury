module Gemfury
  class Client
    class Handle503 < Faraday::Middleware
      def call(env)
        # This prevents errors in ParseJson 
        @app.call(env).on_complete do |out|
          out[:body] = '' if out[:status] == 503
        end
      end
    end
  end
end