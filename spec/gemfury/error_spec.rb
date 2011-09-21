require 'spec_helper'

describe Gemfury::Error do
  before do
    @client = Gemfury::Client.new
    @req_stub = stub_get("status/version")
  end

  it 'should throw Unauthorized for a 401 response' do
    @req_stub.to_return(:body => "{}", :status => 401)
    lambda {
      @client.check_version
    }.should raise_exception(Gemfury::Unauthorized)
  end

  it 'should throw NotFound for a 404 response' do
    @req_stub.to_return(:body => "{}", :status => 404)
    lambda {
      @client.check_version
    }.should raise_exception(Gemfury::NotFound)
  end

  it 'should throw Error for any other response' do
    @req_stub.to_return(:body => "{}", :status => 302)
    lambda {
      @client.check_version
    }.should raise_exception(Gemfury::Error)
  end
end
