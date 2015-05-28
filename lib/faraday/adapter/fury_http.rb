# This is a Faraday adapter that bypasses Faraday's response body
# processing and streams body to STDOUT for text requests

class Faraday::Adapter
  class FuryHttp < NetHttp
    def perform_request(http, env)
      accept = env.request_headers['Accept']
      return super if accept !~ /text\z/

      # Stream response body to STDOUT on success
      http.request(create_request(env)) do |resp|
        unless resp.is_a?(Net::HTTPSuccess)
          resp.body # Cache error body
        else
          resp.read_body do |chunk|
            $stdout.print(chunk)
            $stdout.flush
          end

          # Prevent #body from calling #read_body again
          klass = (class << resp; self; end)
          klass.send(:define_method, :body) { nil }
        end

        # Return response to NetHttp adapter
        return resp
      end
    end
  end

  register_middleware(:fury_http => FuryHttp)
end
