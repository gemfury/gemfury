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

    context 'when config keys are strings' do
      class MyAppStringConfig < Gemfury::Command::App
        no_commands do
          def read_config_file
            { "gemfury_api_key" => 'DEADBEEF' }
          end
        end
      end
      it 'should upload a valid gem ' do
        stub_uploads
        args = ['push', fixture('fury-0.0.2.gem')]
        out = capture(:stdout) { MyAppStringConfig.start(args) }
        ensure_gem_uploads(out, 'fury')
      end
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