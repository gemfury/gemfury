require 'spec_helper'
require 'json'

describe Gemfury::Client do
  before do
    @client = Gemfury::Client.new
  end

  describe '#check_version' do
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
  end

  describe '#get_access_token' do
    it 'should return the access token for correct' do
      stub_post("access_token").to_return(:body => access_token_fixture)

      token = @client.get_access_token('test@test.com', '123')
      token.should eq('TestToken')

      a_post("access_token").with(
        :body => { :email => 'test@test.com', :password => '123' }
      ).should have_been_made.once
    end

    it 'should raise an unauthorized error for bad credentials' do
      stub_post("access_token").to_return(:status => 401)

      lambda do
        @client.get_access_token('test@test.com', '123')
      end.should raise_error(Gemfury::Unauthorized)
    end
  end

  describe '#push_gems' do
    before do
      stub_post("gems")
    end

    describe 'without authentication' do
      it 'should throw an authentication error without an api key' do
        lambda do
          @client.user_api_key = nil
          @client.push_gem(['gemfile'])
        end.should raise_error(Gemfury::Unauthorized)
      end

      it 'should throw an authentication error on a bad key' do
        lambda do
          stub_post("gems").to_return(:status => 401)
          @client.user_api_key = 'MyWrongApiKey'
          @client.push_gem(['gemfile'])
        end.should raise_error(Gemfury::Unauthorized)
      end
    end

    describe 'while authenticated' do
      before { @client.user_api_key = 'MyAuthKey' }

      it 'should upload valid gems' do
        gem_file = File.new(fixture('fury-0.0.2.gem'))
        @client.push_gem(gem_file)
        a_post("gems").should have_been_made
      end
    end
  end

  def version_fixture(version = Gemfury::VERSION)
    ::MultiJson.encode(:version => version)
  end

  def access_token_fixture
    ::MultiJson.encode(:access_token => 'TestToken')
  end
end
