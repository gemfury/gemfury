# frozen_string_literal: true

require 'spec_helper'

describe Gemfury::Command::App do
  Endpoint = 'www.gemfury.com'
  class MyApp < Gemfury::Command::App
    no_commands do
      def read_config_file
        { gemfury_api_key: 'DEADBEEF' }
      end
    end

    # rspec-mocks re-defines the following methods as part of observing its invocations.
    # it is pre-empted here, to avoid warnings from Thor for having methods without descriptions.
    desc 'die!', 'this is not a command', hide: true
    def die!(_msg, err = nil, _command = nil)
      raise err
    end

    desc '__die!_without_any_instance__', 'this is not a command', hide: true
    alias_method '__die!_without_any_instance__', 'die!'
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
      body = MultiJson.encode(name: 'my-name')
      stub_get('users/me').to_return(body: body)

      out = capture(:stdout) { MyApp.start(['login'], shell: thor_sh) }
      expect(a_get('users/me')).to have_been_made
      expect(out).to include('You are logged in as "my-name"')
    end

    it 'should prompt user if no credentials' do
      highline = double('HighLine')
      expect(highline).to receive(:say).with('Please enter your Gemfury credentials.')
      expect(highline).to receive(:ask).with('Email: ').and_return('me@example.com')
      expect(highline).to receive(:ask).with('Password: ').and_return('example123')
      expect(HighLine).to receive(:new).and_return(highline)

      # Issue get_access_token request with credentials
      body = MultiJson.encode(token: 'boom')
      stub_post('login', api_format: :text).to_return(body: body)

      # Issue request to get account information
      body = MultiJson.encode(name: 'my-name')
      stub_get('users/me').to_return(body: body)

      out = capture(:stdout) { LoginTestApp.start(['login'], shell: thor_sh) }
      expect(out).to include('You are logged in as "my-name"')

      expect(a_post('login', body: 'email=me%40example.com&password=example123')).to have_been_made
      expect(a_get('users/me')).to have_been_made
    end
  end

  describe '#logout' do
    let(:thor_sh) { Thor::Base.shell.new }

    it 'should ignore command if without user confirmation' do
      expect(thor_sh).to receive(:yes?).with('Are you sure you want to log out? [yN]').and_return(false)
      out = capture(:stdout) { MyApp.start(['logout'], shell: thor_sh) }
      expect(a_post('logout')).to_not have_been_made
      expect(out).to be_empty
    end

    it 'should ignore command if without user confirmation' do
      expect(thor_sh).to receive(:yes?).with('Are you sure you want to log out? [yN]').and_return(true)
      stub_post('logout').to_return(body: '')
      out = capture(:stdout) { MyApp.start(['logout'], shell: thor_sh) }
      expect(a_post('logout')).to have_been_made
      expect(out).to eq("You have been logged out\n")
    end
  end

  describe '#sharing' do
    let(:thor_sh) { Thor::Base.shell.new }

    it 'should list collaborators with permissions info' do
      stub_get('users/me').to_return(body: fixture('me.json'))
      stub_get('collaborators').to_return(body: fixture('collaborators.json'))

      out = capture(:stdout) { MyApp.start(['sharing'], shell: thor_sh) }
      lines = out.split(/\s*\n/)[1..]

      expect(lines[2]).to match(/^user1\s+owner$/)
      expect(lines[3]).to match(/^user2\s+push$/)
    end

    it 'should list collaborators of org with permissions info' do
      stub_get('users/me').to_return(body: fixture('org.json'))
      stub_get('collaborators').to_return(body: fixture('collaborators.json'))

      out = capture(:stdout) { MyApp.start(['sharing'], shell: thor_sh) }
      lines = out.split(/\s*\n/)[1..]

      expect(lines[2]).to match(/^user2\s+push$/)
      expect(lines[3]).to match(/^user3\s+push$/)
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
      args = ['push', path_to_fixture('fury-0.0.2.gem')]
      out = capture(:stdout) { MyApp.start(args) }
      ensure_gem_uploads(out, 'fury')
    end

    it 'should fail if a version already exists' do
      stub_uploads_to_return_version_exists
      app_should_die(/There was a problem uploading at least 1 package/, Gemfury::DupeVersion)
      args = ['push', path_to_fixture('fury-0.0.2.gem')]
      out = capture(:stdout) { MyApp.start(args) }
      ensure_gem_uploads_with_error(out, [], ['fury'])
    end

    it 'should upload multiple packages' do
      stub_uploads
      args = ['push', path_to_fixture('fury-0.0.2.gem'), path_to_fixture('bar-0.0.2.gem')]
      out = capture(:stdout) { MyApp.start(args) }
      ensure_gem_uploads(out, 'bar', 'fury')
    end

    it 'should fail if at least 1 failed while others should succeed' do
      stub_uploads
      stub_uploads_to_return_version_exists('fury-0.0.2.gem')
      app_should_die(/There was a problem uploading at least 1 package/, Gemfury::DupeVersion)
      args = ['push', path_to_fixture('fury-0.0.2.gem'), path_to_fixture('bar-0.0.2.gem')]
      out = capture(:stdout) { MyApp.start(args) }
      ensure_gem_uploads_with_error(out, ['bar'], ['fury'])
    end

    it 'should upload with progress bar for large files' do
      stub_uploads
      gemfile = fixture('fury-0.0.2.gem')
      gemfile_path = path_to_fixture('fury-0.0.2.gem')

      fsize = 50_001
      pb = ProgressBar.create(total: fsize)

      allow($stdout).to receive(:tty?).and_return(true)
      allow_any_instance_of(StringIO).to receive(:tty?).and_return(true)

      expect(pb).to receive(:'progress=').once
      expect(ProgressBar).to receive(:create).and_return(pb)
      expect(File).to receive(:new).with(gemfile_path).and_return(gemfile)
      expect(gemfile).to receive(:size).and_return(fsize)

      args = ['push', gemfile_path]
      out = capture(:stdout) { MyApp.start(args) }
      ensure_gem_uploads(out, 'fury')
    end

    it 'should upload quietly for large files' do
      stub_uploads
      gemfile = path_to_fixture('fury-0.0.2.gem')

      expect(Gemfury::Command::App::ProgressIO).to_not receive(:new)

      args = ['push', '--quiet', gemfile]
      out = capture(:stdout) { MyApp.start(args) }
      ensure_gem_uploads(out, 'fury', quiet: true)
    end

    context 'when passing api_token via the commandline' do
      it 'should upload a valid gem' do
        stub_uploads
        args = ['push', path_to_fixture('fury-0.0.2.gem'), "--api_token='DEADBEEF'"]
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
      MyApp.start(%w[migrate deadbeef])
      expect(a_request(:any, Endpoint)).not_to have_been_made
    end

    it 'should not upload gems without confirmation' do
      stub_uploads
      sh = Thor::Base.shell.new
      expect(sh).to receive(:yes?).and_return(false)
      args = ['migrate', fixture_path]
      out = capture(:stdout) { MyApp.start(args, shell: sh) }
      expect(a_post('gems')).not_to have_been_made
      expect(out).to match(/bar.*/)
      expect(out).to match(/fury.*/)
    end

    it 'should upload gems after confirmation' do
      stub_uploads
      sh = Thor::Base.shell.new
      expect(sh).to receive(:yes?).and_return(true)
      args = ['migrate', fixture_path]
      out = capture(:stdout) { MyApp.start(args, shell: sh) }
      ensure_gem_uploads(out, 'bar', 'fury')
    end

    context 'when passing api_token via the commandline' do
      it 'should upload gems after confirmation' do
        stub_uploads
        sh = Thor::Base.shell.new
        expect(sh).to receive(:yes?).and_return(true)
        args = ['migrate', fixture_path, "--api_token='DEADBEEF'"]
        out = capture(:stdout) { Gemfury::Command::App.start(args, shell: sh) }
        ensure_gem_uploads(out, 'bar', 'fury')
      end
    end
  end

  describe '#git_rebuild' do
    let(:thor_sh) { Thor::Base.shell.new }

    it 'should cause errors for no repo specified' do
      out = capture(:stderr) { MyApp.start(['git:rebuild'], shell: thor_sh) }
      expect(a_request(:any, Endpoint)).not_to have_been_made
      expect(out).to match(/^ERROR:/)
    end

    it 'should rebuild repo and print output' do
      url  = 'git/repos/me/example/builds'
      opts = { body: 'Package build output & success :)' }
      stub_post(url, api_format: :text).to_return(opts)

      args = ['git:rebuild', 'example']
      out = capture(:stdout) { MyApp.start(args, shell: thor_sh) }
      expect(a_post(url, api_format: :text)).to have_been_made
      expect(out).to include(opts[:body])
    end

    it 'should rebuild repo at revision' do
      url  = 'git/repos/me/example/builds'
      opts = { body: 'Package build output & success :)' }
      stub_post(url, api_format: :text).to_return(opts)

      args = ['git:rebuild', 'example', '--revision', 'my-tag']
      out = capture(:stdout) { MyApp.start(args, shell: thor_sh) }
      params = { body: { build: { revision: 'my-tag' } } }
      expect(a_post(url, api_format: :text).with(params)).to have_been_made
      expect(out).to include(opts[:body])
    end
  end

  describe '#versions' do
    let(:thor_sh) { Thor::Base.shell.new }
    let(:dtformat) { '"%FT%T%:z"' }

    it 'should return created at in date and time format' do
      stub_get('gems/example/versions').to_return(body: fixture('versions.json'))

      out = capture(:stdout) { MyApp.start(%w[versions example], shell: thor_sh) }
      expect(a_get('gems/example/versions')).to have_been_made

      lines = parse_out_lines(out)

      vex = /(^\d+(\.[A-Za-z0-9]+)*)\s+(\S+)\s+(\d{4}-\d{2}-\d{2}\s\d{2}:\d{2})$/
      expect(lines[2]).to match(vex)
      expect(lines[3]).to match(vex)
    end

    context 'reference time of day' do
      it 'should show ago in secs' do
        v_fixture = fixture('versions.json').read
        v_fixture.gsub!(/"2019-05-01T.+"/, (Time.now - 20).strftime(dtformat))

        stub_get('gems/example/versions').to_return(body: v_fixture)

        out = capture(:stdout) { MyApp.start(%w[versions example], shell: thor_sh) }
        lines = parse_out_lines(out)

        vex = /(^\d+(\.[A-Za-z0-9]+)*)\s+(\S+)\s+(\d{4}-\d{2}-\d{2} \d{2}:\d{2}) (\(~ \d+s ago\))$/
        expect(lines[4]).to match(vex)
      end

      it 'should show ago in minutes' do
        v_fixture = fixture('versions.json').read
        v_fixture.gsub!(/"2019-05-02T.+"/, (Time.now - 2000).strftime(dtformat))

        stub_get('gems/example/versions').to_return(body: v_fixture)

        out = capture(:stdout) { MyApp.start(%w[versions example], shell: thor_sh) }
        lines = parse_out_lines(out)

        vex = /(^\d+(\.[A-Za-z0-9]+)*)\s+(\S+)\s+(\d{4}-\d{2}-\d{2} \d{2}:\d{2}) (\(~ \d+m ago\))$/
        expect(lines[5]).to match(vex)
      end

      it 'should show ago in hours' do
        v_fixture = fixture('versions.json').read
        v_fixture.gsub!(/"2019-05-03T.+"/, (Time.now - 20_000).strftime(dtformat))

        stub_get('gems/example/versions').to_return(body: v_fixture)

        out = capture(:stdout) { MyApp.start(%w[versions example], shell: thor_sh) }
        lines = parse_out_lines(out)

        vex = /(^\d+(\.[A-Za-z0-9]+)*)\s+(\S+)\s+(\d{4}-\d{2}-\d{2} \d{2}:\d{2}) (\(~ \d+h ago\))$/
        expect(lines[6]).to match(vex)
      end
    end
  end

  describe '#git_config' do
    let(:thor_sh) { Thor::Base.shell.new }

    it 'should cause errors for no repo specified' do
      out = capture(:stderr) { MyApp.start(['git:config'], shell: thor_sh) }
      expect(a_request(:any, Endpoint)).not_to have_been_made
      expect(out).to match(/^ERROR:/)
    end

    it 'should print configuration variables' do
      url  = 'git/repos/me/example/config-vars'
      opts = { body: fixture('git_config.json') }
      stub_get(url).to_return(opts)

      args = ['git:config', 'example']
      out = capture(:stdout) { MyApp.start(args, shell: thor_sh) }
      expect(a_get(url)).to have_been_made

      expect(out).to include('example build config')
      expect(out).to match(/^HELLO:\s*WORLD$/)
      expect(out).to match(/^SUPER:\s*SECRET$/)
    end
  end

  describe '#git_config_set' do
    let(:thor_sh) { Thor::Base.shell.new }

    it 'should cause errors for no repo specified' do
      out = capture(:stderr) { MyApp.start(['git:config:set'], shell: thor_sh) }
      expect(a_request(:any, Endpoint)).not_to have_been_made
      expect(out).to match(/^ERROR:/)
    end

    it 'should update configuration variables' do
      url  = 'git/repos/me/example/config-vars'
      opts = { body: fixture('git_config.json') }
      stub_patch(url).to_return(opts)

      new_vars = { 'NEW' => 'VAR', 'UPDATE' => 'NOW' }
      args = ['git:config:set', 'example'] + new_vars.map { |k, v| "#{k}=#{v}" }

      out = capture(:stdout) { MyApp.start(args, shell: thor_sh) }
      body = Faraday::NestedParamsEncoder.encode('config_vars' => new_vars)
      expect(a_patch(url, body: body)).to have_been_made
      expect(out).to include('Updated example build config')
    end
  end

  describe '#git_config_unset' do
    let(:thor_sh) { Thor::Base.shell.new }

    it 'should cause errors for no repo specified' do
      out = capture(:stderr) { MyApp.start(['git:config:unset'], shell: thor_sh) }
      expect(a_request(:any, Endpoint)).not_to have_been_made
      expect(out).to match(/^ERROR:/)
    end

    it 'should remove configuration variables' do
      url  = 'git/repos/me/example/config-vars'
      opts = { body: fixture('git_config.json') }
      stub_patch(url).to_return(opts)

      new_vars = { 'NEW' => nil, 'UPDATE' => nil }
      args = ['git:config:unset', 'example'] + new_vars.map { |k, _v| k }

      out = capture(:stdout) { MyApp.start(args, shell: thor_sh) }
      body = Faraday::NestedParamsEncoder.encode('config_vars' => new_vars)
      expect(a_patch(url, body: body)).to have_been_made
      expect(out).to include('Updated example build config')
    end
  end

  private

  def escape(str)
    CGI.escape(str)
  end

  def parse_out_lines(out)
    out.split(/\s*\n/)[1..]
  end

  def app_should_die(*args)
    expect_any_instance_of(MyApp).to receive(:die!).with(*args)
  end

  def stub_uploads
    stub_post('uploads', endpoint: Gemfury.pushpoint)
      .to_return(body: fixture('uploads.json'))
  end

  def stub_uploads_to_return_version_exists(only_gem = nil)
    stub = stub_post('uploads', endpoint: Gemfury.pushpoint)
    unless only_gem.nil?
      stub = stub.with { |req| req.body =~ /Content-Disposition: form-data;.+ filename="#{only_gem}"/ }
    end
    stub.to_return(status: 409, body: fixture('uploads_version_exists.json'))
  end

  def ensure_gem_uploads(out, *gems, quiet: false)
    expect(a_post('uploads', endpoint: Gemfury.pushpoint))
      .to have_been_made.times(gems.size)

    if quiet
      expect(out).to be_empty
    else
      gems.each do |g|
        expect(out).to match(/Uploading #{g}(.*)(\.\.\.\n)?- done/)
      end
    end
  end

  def ensure_gem_uploads_with_error(out, ok_gems, error_gems)
    expect(a_post('uploads', endpoint: Gemfury.pushpoint))
      .to have_been_made.times((ok_gems + error_gems).size)

    ok_gems.each do |g|
      expect(out).to match(/Uploading #{g}.+- done/)
    end

    error_gems.each do |g|
      expect(out).to_not match(/Uploading #{g}.+- done/)
    end
  end
end
