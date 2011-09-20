require 'spec_helper'
require 'json'

describe Gemfury::Client do
  before do
    @client = Gemfury::Client.new
    stub_version_request
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

  shared_examples 'API without authentication' do
    before { stub_api_method.to_return(:status => 401) }

    it 'should throw an authentication error without an api key' do
      lambda do
        @client.user_api_key = nil
        send_api_request
      end.should raise_error(Gemfury::Unauthorized)
    end

    it 'should throw an authentication error on a bad key' do
      lambda do
        @client.user_api_key = 'MyWrongApiKey'
        send_api_request
      end.should raise_error(Gemfury::Unauthorized)
    end
  end

  describe '#push_gems' do
    let(:stub_api_method)  { stub_post("gems") }

    it_should_behave_like 'API without authentication' do
      let(:send_api_request) { @client.push_gem(['gemfile']) }
    end

    describe 'while authenticated' do
      before do
        @client.user_api_key = 'MyAuthKey'
        stub_api_method
      end

      it 'should upload valid gems' do
        gem_file = File.new(fixture('fury-0.0.2.gem'))
        @client.push_gem(gem_file)
        a_post("gems").should have_been_made
      end
    end
  end

  describe '#list' do
    let(:stub_api_method)  { stub_get("gems") }
    let(:send_api_request) { @client.list }

    it_should_behave_like 'API without authentication'

    describe 'while authenticated' do
      before do
        stub_api_method.to_return(:body => fixture('gems.json'))
        @client.user_api_key = 'MyAuthKey'
      end

      it 'should list uploaded gems' do
        gems_list = send_api_request
        a_get("gems").should have_been_made
        gems_list.size.should eq(1)
        gems_list.first['name'].should eq('example')
      end
    end
  end

  describe '#versions' do
    let(:stub_api_method)  { stub_get("gems/example/versions") }
    let(:send_api_request) { @client.versions('example') }

    it_should_behave_like 'API without authentication'

    describe 'while authenticated' do
      before do
        stub_api_method.to_return(:body => fixture('versions.json'))
        @client.user_api_key = 'MyAuthKey'
      end

      it 'should list gem versions' do
        versions = send_api_request
        a_get("gems/example/versions").should have_been_made
        versions.size.should eq(2)
        versions.first['slug'].should eq('example-0.0.1')
      end
    end
  end

  describe '#yank_version' do
    let(:stub_api_method)  { stub_delete("gems/example/versions/0.0.1") }
    let(:send_api_request) { @client.yank_version('example', '0.0.1') }

    it_should_behave_like 'API without authentication'

    describe 'while authenticated' do
      before do
        @client.user_api_key = 'MyAuthKey'
        stub_api_method
      end

      it 'should upload valid gems' do
        send_api_request
        a_delete("gems/example/versions/0.0.1").should have_been_made
      end
    end
  end

  def access_token_fixture
    ::MultiJson.encode(:access_token => 'TestToken')
  end
end
