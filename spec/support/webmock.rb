# Define a_get, a_post, etc and stub_get, stub_post, etc
[:delete, :get, :post, :put].each do |method|
  self.class.send(:define_method, "a_#{method}") do |path, *opts|
    prefix = Gemfury.send(opts == [2] ? :endpoint2 : :endpoint)
    a_request(method, prefix + path).with(
      :headers => {
        'Accept'        => 'application/json',
        'X-Gem-Version' => Gemfury::VERSION
      }
    )
  end

  self.class.send(:define_method, "stub_#{method}") do |path, *opts|
    prefix = Gemfury.send(opts == [2] ? :endpoint2 : :endpoint)
    stub_request(method, prefix + path)
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