require 'spec_helper'
require 'json'

class TestClient
  include Gemfury::Client
end

describe Gemfury::Client do
  before do
    @client = TestClient.new
  end

  it 'should pass a correct version check' do
    stub_get("status/version").
    to_return(:body => version_fixture)

    @client.check_version
  end

  it 'should fail a future version check' do
    lambda do
      stub_get("status/version").
      to_return(:body => version_fixture('99.0.0'))

      @client.check_version
    end.should raise_error(StandardError, /update/i)
  end

  def version_fixture(version = Gemfury::VERSION)
    ::MultiJson.encode(:version => version)
  end
end
