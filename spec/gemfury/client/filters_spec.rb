require 'spec_helper'
require 'json'

describe Gemfury::Client::Filters do
  before do
    @client = Gemfury::Client.new(:user_api_key => 'MyApiKey')
    stub_get('gems')
  end

  describe "without version check" do
    before { @client.check_gem_version = false }

    it 'should not call for a version check' do
      lambda { @client.list }.should_not raise_error
      a_get("status/version").should_not have_been_made
    end
  end

  describe %Q(with version check against "#{Gemfury::VERSION}") do
    before { @client.check_gem_version = true }

    after do
      a_get("status/version").should have_been_made
    end

    [Gemfury::VERSION, "~> #{Gemfury::VERSION}", '>= 0.0.1'].each do |version|
      it %Q(should pass a version check for "#{version}") do
        stub_version_request(version)
        lambda { @client.list }.should_not raise_error
      end
    end

    ['~> 99999.0.0', '~> 0.0.1', '0.0.1'].each do |version|
      it %Q(should fail a version check for "#{version}") do
        stub_version_request(version)
        lambda { @client.list }.should raise_error(Gemfury::InvalidGemVersion)
      end
    end
  end
end