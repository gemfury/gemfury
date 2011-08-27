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

  describe "with version check (#{Gemfury::VERSION})" do
    before { @client.check_gem_version = true }

    after do
      a_get("status/version").should have_been_made
    end

    it 'should pass an exact version check' do
      stub_version_request
      lambda { @client.list }.should_not raise_error
    end

    it 'should pass a spermy version check' do
      stub_version_request("~> #{Gemfury::VERSION}")
      lambda { @client.list }.should_not raise_error
    end

    it 'should fail a higher version check' do
      stub_version_request(Gemfury::VERSION.gsub(/^(\d+)(.*)$/) do
        "~> #{$1.to_i + 1}#{$2}"
      end)

      lambda {
        @client.list
      }.should raise_error(Gemfury::InvalidGemVersion)
    end
  end
end