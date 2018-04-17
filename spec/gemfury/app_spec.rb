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

    it 'should upload multiple packages' do
      stub_uploads
      args = ['push', fixture('fury-0.0.2.gem'), fixture('bar-0.0.2.gem')]
      out = capture(:stdout) { MyApp.start(args) }
      ensure_gem_uploads(out, 'bar', 'fury')
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

  def ensure_gem_uploads(out, *gems)
    expect(a_post('uploads', :endpoint => Gemfury.pushpoint)).
      to have_been_made.times(gems.size)

    gems.each do |g|
      expect(out).to match(/Uploading #{g}.*done/)
    end
  end
end
