#
## General helpers
#

RSpec.configure do |config|
  def stub_version_request(version = Gemfury::VERSION)
    body = ::MultiJson.encode(:version => version)
    stub_get("status/version").to_return(:body => body)
  end
end
