# Define a_get, a_post, etc and stub_get, stub_post, etc
[:delete, :get, :post, :put, :patch].each do |method|
  self.class.send(:define_method, "a_#{method}") do |path, *args|
    opts = args.last.is_a?(Hash) ? args.pop : {}
    ver = args.first || opts[:api_version] || 1
    fmt = opts[:api_format] || :json
    a_request(method, Gemfury.endpoint + path).with(
      :headers => {
        'Accept' => "application/vnd.fury.v#{ver}+#{fmt}",
        'X-Gem-Version' => Gemfury::VERSION
      }
    )
  end

  self.class.send(:define_method, "stub_#{method}") do |path, *args|
    stub_request(method, Gemfury.endpoint + path)
  end
end

# Fixture helpers
def fixture_path
  File.expand_path("../../fixtures", __FILE__)
end

def fixture(file)
  File.new(fixture_path + '/' + file)
end

# Always Always Stub S3 Upload to succeed
class ::Gemfury::Client
  def s3_put_file(uri, file)
    Faraday::Response.new.finish(:status => 200, :body => '')
  end
end