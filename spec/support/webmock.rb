# Define a_get, a_post, etc and stub_get, stub_post, etc
[:delete, :get, :post, :put].each do |method|
  self.class.send(:define_method, "a_#{method}") do |path|
    a_request(method, Gemfury.endpoint + path).with(
      :headers => {
        'Accept'        => 'application/json',
        'X-Gem-Version' => Gemfury::VERSION
      }
    )
  end

  self.class.send(:define_method, "stub_#{method}") do |path|
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