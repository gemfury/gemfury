# frozen_string_literal: true

# This is a Faraday adapter that bypasses Faraday's response body
# processing and streams body to STDOUT for text requests

class Faraday::Adapter
  class FuryHttp < NetHttp
    def request_with_wrapped_block(http, env, &block)
      is_text = env.request_headers['Accept'] =~ /text\z/
      return super if !block.nil? || !is_text

      # Stream chunks directly to STDOUT
      resp = super(http, env) do |chunk|
        $stdout.print(chunk)
        $stdout.flush
      end

      # Client sees nil body
      resp.body = nil
      resp
    end
  end

  register_middleware(fury_http: FuryHttp)
end
