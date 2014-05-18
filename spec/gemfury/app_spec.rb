require 'spec_helper'

describe Gemfury::Command::App do
  Endpoint = "www.gemfury.com"
  class MyApp < Gemfury::Command::App
    no_commands do
      def read_config_file
        { :gemfury_api_key => 'DEADBEEF' }
      end

      def account
        nil
      end
    end
  end

  describe '#push' do
    it 'should cause errors for no gems specified' do
      app_should_die(/No valid packages/, nil, :push)
      MyApp.start(['push'])
      a_request(:any, Endpoint).should_not have_been_made
    end

    it 'should cause errors for an invalid gem path' do
      app_should_die(/No valid packages/, nil, :push)
      MyApp.start(['push', 'bad.gem'])
      a_request(:any, Endpoint).should_not have_been_made
    end

    it 'should upload a valid gem' do
      stub_uploads
      args = ['push', fixture('fury-0.0.2.gem')]
      out = capture(:stdout) { MyApp.start(args) }
      ensure_gem_uploads(out, 'fury')
    end

    it 'should upload multiple packages' do
      stub_uploads
      args = ['push', fixture('fury-0.0.2.gem'), fixture('bar-0.0.2.gem')]
      out = capture(:stdout) { MyApp.start(args) }
      ensure_gem_uploads(out, 'bar', 'fury')
    end
  end

  describe '#migrate' do
    it 'should cause errors for no gems specified' do
      app_should_die(/No valid packages/, nil, :migrate)
      MyApp.start(['migrate'])
      a_request(:any, Endpoint).should_not have_been_made
    end

    it 'should cause errors for an invalid path' do
      app_should_die(/No valid packages/, nil, :migrate)
      MyApp.start(['migrate', 'deadbeef'])
      a_request(:any, Endpoint).should_not have_been_made
    end

    it 'should not upload gems without confirmation' do
      stub_uploads
      sh = Thor::Base.shell.new
      sh.should_receive(:yes?).and_return(false)
      args = ['migrate', fixture_path]
      out = capture(:stdout) { MyApp.start(args, :shell => sh) }
      a_post("gems").should_not have_been_made
      out.should =~ /bar.*/
      out.should =~ /fury.*/
    end

    it 'should upload gems after confirmation' do
      stub_uploads
      sh = Thor::Base.shell.new
      sh.should_receive(:yes?).and_return(true)
      args = ['migrate', fixture_path]
      out = capture(:stdout) { MyApp.start(args, :shell => sh) }
      ensure_gem_uploads(out, 'bar', 'fury')
    end
  end

  describe 'impersonation' do
    before do
      stub_uploads
      @args = ['push', fixture('fury-0.0.2.gem')]
      @client = Gemfury::Client.new :user_api_key => 'DEADBEEF'
    end

    context 'when :as option is provided to the command' do
      before do
        MyApp.any_instance.stub(:options).and_return(:as => 'useraccount'})
      end

      it 'should send an :account to the client' do
        Gemfury::Client.should_receive(:new).with(hash_including(:account => 'useraccount')).at_least(:once).and_return(@client)
        capture(:stdout) { MyApp.start(@args) }
      end
    end

    context 'when @account is set in authorization' do
      before do
        MyApp.any_instance.stub(:account).and_return('useraccount')
      end

      it 'should send an :account to the client' do
        Gemfury::Client.should_receive(:new).with(hash_including(:account => 'useraccount')).at_least(:once).and_return(@client)
        capture(:stdout) { MyApp.start(@args) }
      end

      context 'when :as is also provided' do
        before do
          MyApp.any_instance.stub(:options).and_return({:as => 'as-account'})
        end

        it 'should send the :as account to the client' do
          Gemfury::Client.should_receive(:new).with(hash_including(:account => 'as-account')).at_least(:once).and_return(@client)
          capture(:stdout) { MyApp.start(@args) }
        end
      end
    end

    context 'when no impersonation exists' do
      it 'should NOT send an :account to the client' do
        Gemfury::Client.should_receive(:new).with(hash_excluding(:account)).at_least(:once).and_return(@client)
        capture(:stdout) { MyApp.start(@args) }
      end
    end
  end

private
  def app_should_die(*args)
    MyApp.any_instance.should_receive(:die!).with(*args)
  end

  def stub_uploads
    body = fixture('upload.json').read
    stub_post("uploads", 2).to_return(:body => body)
    stub_put("uploads/WTFBBQ123", 2).to_return(:body => body)
  end

  def ensure_gem_uploads(out, *gems)
    a_post("uploads", 2).should have_been_made.times(gems.size)
    a_put("uploads/WTFBBQ123", 2).should have_been_made.times(gems.size)
    gems.each do |g|
      out.should =~ /Uploading #{g}.*done/
    end
  end
end
