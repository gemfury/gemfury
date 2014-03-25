require 'spec_helper'

describe Gemfury::Error do
  before do
    @client = Gemfury::Client.new
    @client.user_api_key = 'MyAuthKey'
    @req_stub = stub_get("gems")
  end

  it 'should throw Unauthorized for a 401 response' do
    @req_stub.to_return(:body => "{}", :status => 401)
    lambda {
      @client.list
    }.should raise_exception(Gemfury::Unauthorized)
  end

  it 'should throw NotFound for a 404 response' do
    @req_stub.to_return(:body => "{}", :status => 404)
    lambda {
      @client.list
    }.should raise_exception(Gemfury::NotFound)
  end

  it 'should throw TimeoutError for a 503 response' do
    @req_stub.to_return(:body => "{}", :status => 503)
    lambda {
      @client.list
    }.should raise_exception(Gemfury::TimeoutError)
  end

  it 'should throw Error for any other non-success response' do
    @req_stub.to_return(:body => "{}", :status => 302)
    lambda {
      @client.list
    }.should raise_exception(Gemfury::Error)
  end

  describe 'bad request error' do
    {
      'GemVersionError' => Gemfury::InvalidGemVersion,
      'Forbidden'       => Gemfury::Forbidden,
      'InvalidGemFile'  => Gemfury::CorruptGemFile,
      'DupeVersion'     => Gemfury::DupeVersion,
      'RandomError'     => Gemfury::Error
    }.each do |type, klass|
      it "#{type} should raise #{klass.name}" do
        @req_stub.to_return(bad_request(type))
        lambda {
          @client.list
        }.should raise_exception(klass)
      end
    end
  end

private
  def bad_request(type, message = "Herp derp")
    { :status => 400, :body => MultiJson.encode(
        :error => { :type => type, :message => message }
    )}
  end
end
