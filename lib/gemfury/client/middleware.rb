# frozen_string_literal: true

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

    class ParseJson < Faraday::Middleware
      def parse(body)
        body =~ /\A\s*\z/ ? nil : MultiJson.decode(body)
      end

      def on_complete(response)
        ok = response.request_headers['Accept'] =~ /json\z/
        response.body = parse(response.body) if ok
      end
    end
  end
end
