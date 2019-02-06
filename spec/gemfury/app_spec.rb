require 'spec_helper'

describe Gemfury::Command::App do
  Endpoint = "www.gemfury.com"
  class MyApp < Gemfury::Command::App
    no_commands do
      def read_config_file
        { :gemfury_api_key => 'DEADBEEF' }
      end
    end
  end

  class LoginTestApp < Gemfury::Command::App
    no_commands do
      def load_credentials!
        @user_api_key = nil
      end
    end
  end

  describe '#login' do
    let(:thor_sh) { Thor::Base.shell.new }

    it 'should print current user if already logged in' do
      body = MultiJson.encode(:name => 'my-name')
      stub_get("users/me").to_return(:body => body)

      out = capture(:stdout) { MyApp.start(['login'], :shell => thor_sh) }
      expect(a_get("users/me")).to have_been_made
      expect(out).to include(%Q(You are logged in as "my-name"))
    end

    it 'should prompt user if no credentials' do
      highline = double('HighLine')
      expect(highline).to receive(:say).with("Please enter your Gemfury credentials.")
      expect(highline).to receive(:ask).with('Email: ').and_return("me@example.com")
      expect(highline).to receive(:ask).with('Password: ').and_return("example123")
      expect(HighLine).to receive(:new).and_return(highline)

      # Issue get_access_token request with credentials
      body = MultiJson.encode(:token => 'boom')
      stub_post("login", :api_format => :text).to_return(:body => body)

      # Issue request to get account information
      body = MultiJson.encode(:name => 'my-name')
      stub_get("users/me").to_return(:body => body)

      out = capture(:stdout) { LoginTestApp.start(['login'], :shell => thor_sh) }
      expect(out).to include(%Q(You are logged in as "my-name"))

      expect(a_post("login", :body => 'email=me%40example.com&password=example123')).to have_been_made
      expect(a_get("users/me")).to have_been_made
    end
  end

  describe '#logout' do
    let(:thor_sh) { Thor::Base.shell.new }

    it 'should ignore command if without user confirmation' do
      expect(thor_sh).to receive(:yes?).with("Are you sure you want to log out? [yN]").and_return(false)
      out = capture(:stdout) { MyApp.start(['logout'], :shell => thor_sh) }
      expect(a_post("logout")).to_not have_been_made
      expect(out).to be_empty
    end

    it 'should ignore command if without user confirmation' do
      expect(thor_sh).to receive(:yes?).with("Are you sure you want to log out? [yN]").and_return(true)
      stub_post("logout").to_return(:body => '')
      out = capture(:stdout) { MyApp.start(['logout'], :shell => thor_sh) }
      expect(a_post("logout")).to have_been_made
      expect(out).to eq("You have been logged out\n")
    end
  end

  describe '#push' do
    it 'should cause errors for no gems specified' do
      app_should_die(/No valid packages/, nil, :push)
      MyApp.start(['push'])
      expect(a_request(:any, Endpoint)).not_to have_been_made
    end

    it 'should cause errors for an invalid gem path' do
      app_should_die(/No valid packages/, nil, :push)
      MyApp.start(['push', 'bad.gem'])
      expect(a_request(:any, Endpoint)).not_to have_been_made
    end

    it 'should upload a valid gem' do
      stub_uploads
      args = ['push', fixture('fury-0.0.2.gem')]
      out = capture(:stdout) { MyApp.start(args) }
      ensure_gem_uploads(out, 'fury')
    end

    it 'should fail if a version already exists' do
      stub_uploads_to_return_version_exists
      app_should_die(/There was a problem uploading at least 1 package/, Gemfury::DupeVersion)
      args = ['push', fixture('fury-0.0.2.gem')]
      out = capture(:stdout) { MyApp.start(args) }
      ensure_gem_uploads_with_error(out, [], [ 'fury' ])
    end

    it 'should upload multiple packages' do
      stub_uploads
      args = ['push', fixture('fury-0.0.2.gem'), fixture('bar-0.0.2.gem')]
      out = capture(:stdout) { MyApp.start(args) }
      ensure_gem_uploads(out, 'bar', 'fury')
    end

    it 'should fail if at least 1 failed while others should succeed' do
      stub_uploads
      stub_uploads_to_return_version_exists('fury-0.0.2.gem')
      app_should_die(/There was a problem uploading at least 1 package/, Gemfury::DupeVersion)
      args = ['push', fixture('fury-0.0.2.gem'), fixture('bar-0.0.2.gem')]
      out = capture(:stdout) { MyApp.start(args) }
      ensure_gem_uploads_with_error(out, [ 'bar' ], [ 'fury' ])
    end

    context 'when passing api_token via the commandline' do
      it 'should upload a valid gem' do
        stub_uploads
        args = ['push', fixture('fury-0.0.2.gem'), "--api_token='DEADBEEF'"]
        out = capture(:stdout) { Gemfury::Command::App.start(args) }
        ensure_gem_uploads(out, 'fury')
      end
    end
  end

  describe '#migrate' do
    it 'should cause errors for no gems specified' do
      app_should_die(/No valid packages/, nil, :migrate)
      MyApp.start(['migrate'])
      expect(a_request(:any, Endpoint)).not_to have_been_made
    end

    it 'should cause errors for an invalid path' do
      app_should_die(/No valid packages/, nil, :migrate)
      MyApp.start(['migrate', 'deadbeef'])
      expect(a_request(:any, Endpoint)).not_to have_been_made
    end

    it 'should not upload gems without confirmation' do
      stub_uploads
      sh = Thor::Base.shell.new
      expect(sh).to receive(:yes?).and_return(false)
      args = ['migrate', fixture_path]
      out = capture(:stdout) { MyApp.start(args, :shell => sh) }
      expect(a_post("gems")).not_to have_been_made
      expect(out).to match(/bar.*/)
      expect(out).to match(/fury.*/)
    end

    it 'should upload gems after confirmation' do
      stub_uploads
      sh = Thor::Base.shell.new
      expect(sh).to receive(:yes?).and_return(true)
      args = ['migrate', fixture_path]
      out = capture(:stdout) { MyApp.start(args, :shell => sh) }
      ensure_gem_uploads(out, 'bar', 'fury')
    end

    context 'when passing api_token via the commandline' do
      it 'should upload gems after confirmation' do
        stub_uploads
        sh = Thor::Base.shell.new
        expect(sh).to receive(:yes?).and_return(true)
        args = ['migrate', fixture_path, "--api_token='DEADBEEF'"]
        out = capture(:stdout) { Gemfury::Command::App.start(args, :shell => sh) }
        ensure_gem_uploads(out, 'bar', 'fury')
      end
    end
  end

  describe '#git_rebuild' do
    let(:thor_sh) { Thor::Base.shell.new }

    it 'should cause errors for no repo specified' do
      MyApp.start(['git:rebuild'])
      expect(a_request(:any, Endpoint)).not_to have_been_made
    end

    it 'should rebuild repo and print output' do
      url  = "git/repos/me/example/builds"
      opts = { :body => 'Package build output & success :)' }
      stub_post(url, :api_format => :text).to_return(opts)

      args = ['git:rebuild', 'example']
      out = capture(:stdout) { MyApp.start(args, :shell => thor_sh) }
      expect(a_post(url, :api_format => :text)).to have_been_made
      expect(out).to include(opts[:body])
    end

    it 'should rebuild repo at revision' do
      url  = "git/repos/me/example/builds"
      opts = { :body => 'Package build output & success :)' }
      stub_post(url, :api_format => :text).to_return(opts)

      args = ['git:rebuild', 'example', '--revision', 'my-tag']
      out = capture(:stdout) { MyApp.start(args, :shell => thor_sh) }
      params = { :body => { :build => { :revision => 'my-tag' }}}
      expect(a_post(url, :api_format => :text).with(params)).to have_been_made
      expect(out).to include(opts[:body])
    end
  end

private
  def app_should_die(*args)
    expect_any_instance_of(MyApp).to receive(:die!).with(*args)
  end

  def stub_uploads
    stub_post('uploads', :endpoint => Gemfury.pushpoint).
      to_return(:body => fixture('uploads.json'))
  end

  def stub_uploads_to_return_version_exists(only_gem = nil)
    stub = stub_post('uploads', :endpoint => Gemfury.pushpoint)
    unless only_gem.nil?
      stub = stub.with{ |req| req.body =~ /Content-Disposition\: form\-data\;.+ filename=\"#{only_gem}\"/ }
    end
    stub.to_return(:status => 409, :body => fixture('uploads_version_exists.json'))
  end

  def ensure_gem_uploads(out, *gems)
    expect(a_post('uploads', :endpoint => Gemfury.pushpoint)).
      to have_been_made.times(gems.size)

    gems.each do |g|
      expect(out).to match(/Uploading #{g}.*done/)
    end
  end

  def ensure_gem_uploads_with_error(out, ok_gems, error_gems)
    expect(a_post('uploads', :endpoint => Gemfury.pushpoint)).
      to have_been_made.times((ok_gems + error_gems).size)

    ok_gems.each do |g|
      expect(out).to match(/Uploading #{g}.+\- done/)
    end

    error_gems.each do |g|
      expect(out).to_not match(/Uploading #{g}.+\- done/)
    end
  end
end
