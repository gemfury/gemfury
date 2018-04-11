require 'spec_helper'

describe Gemfury::Command::Authorization do
  include FakeFS::SpecHelpers
  SampleNetrc = fixture('netrc').read

  class AuthClass
    include Gemfury::Command::Authorization
    attr_reader :user_api_key

    def initialize(key)
      @user_api_key = key
    end

    def client
      Gemfury::Client.new({})
    end

    # Disable legacy config
    def read_config_file
      {}
    end
  end

  before do
    allow(FakeFS::File).to receive(:stat).and_return(double('stat', :mode => "0600".to_i(8)))
    allow(FakeFS::FileUtils).to receive(:chmod)

    Netrc.stub(:default_path).and_return(File.expand_path('../.netrc', __FILE__))
    FileUtils.mkdir_p(File.dirname(Netrc.default_path))
  end

  after do
    FileUtils.rm(Netrc.default_path) rescue nil
  end

  shared_examples 'Authorization#write_credentials' do
    it 'should overwrite credentials to .netrc' do
      auth = AuthClass.new('pass123')
      auth.send(:write_credentials!, 'email@spec.com')
      expect(Netrc.read["api.fury.io"].login).to eq('email@spec.com')
      expect(Netrc.read["git.fury.io"].login).to eq('email@spec.com')
      expect(Netrc.read["api.fury.io"].password).to eq('pass123')
      expect(Netrc.read["git.fury.io"].password).to eq('pass123')
    end
  end

  describe 'without .netrc' do
    before do
      FileUtils.touch(Netrc.default_path)
    end

    it_should_behave_like 'Authorization#write_credentials'

    it 'should return false for has_credentials?' do
      auth = AuthClass.new('pass123')
      expect(auth.has_credentials?).to be_falsey
    end

    it 'should reset API key with load_credentials' do
      auth = AuthClass.new(nil)
      auth.send(:load_credentials!)
      expect(auth.user_api_key).to be_nil
    end

    it 'should not throw error on #wipe_credentials!' do
      expect do
        AuthClass.new(nil).wipe_credentials!
      end.to_not raise_error
    end
  end

  describe 'with existing credentials' do
    before do
      File.open(Netrc.default_path, "w") { |f| f.write(SampleNetrc) }
    end

    it_should_behave_like 'Authorization#write_credentials'

    it 'should return true for has_credentials?' do
      auth = AuthClass.new('pass123')
      expect(auth.has_credentials?).to be_truthy
    end

    it 'should reset API key with load_credentials' do
      auth = AuthClass.new(nil)
      auth.send(:load_credentials!)
      expect(auth.user_api_key).to eq('api_pass')
    end

    it 'should erase credentials with #wipe_credentials!' do
      AuthClass.new(nil).wipe_credentials!
      expect(Netrc.read["api.fury.io"]).to be_nil
      expect(Netrc.read["git.fury.io"]).to be_nil
      expect(Netrc.read["nop.fury.io"]).to_not be_nil
    end
  end
end
