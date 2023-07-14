# frozen_string_literal: true

# Define a_get, a_post, etc and stub_get, stub_post, etc
%i[delete get post put patch].each do |method|
  self.class.send(:define_method, "a_#{method}") do |path, *args|
    opts = args.last.is_a?(Hash) ? args.pop : {}
    ver = args.first || opts[:api_version] || 1
    fmt = opts[:api_format] || :json
    with_opts = {
      headers: {
        'Accept' => format('application/vnd.fury.v%s+%s', ver, fmt),
        'X-Gem-Version' => Gemfury::VERSION
      }
    }

    # Older Ruby doesn't have #slice, so this will do
    with_opts.merge!(opts.reject do |k, _|
      !%i[query body].include?(k)
    end)

    endpoint = opts[:endpoint] || Gemfury.endpoint
    a_request(method, endpoint + path).with(with_opts)
  end

  self.class.send(:define_method, "stub_#{method}") do |path, *args|
    opts = args.last.is_a?(Hash) ? args.pop : {}
    endpoint = opts[:endpoint] || Gemfury.endpoint
    stub_request(method, endpoint + path)
  end
end

# Fixture helpers
def fixture_path
  File.expand_path('../fixtures', __dir__)
end

def path_to_fixture(file)
  File.join(fixture_path, file)
end

def fixture(file)
  File.new(path_to_fixture(file))
end

# Always Always Stub S3 Upload to succeed
class ::Gemfury::Client
  def s3_put_file(_uri, _file)
    Faraday::Response.new.finish(status: 200, body: '')
  end
end
