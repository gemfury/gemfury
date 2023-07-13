require 'spec_helper'

describe Gemfury::Client do
  before do
    @client = Gemfury::Client.new
  end

  describe '#login' do
    it 'should return the access token for correct' do
      stub_post("login").to_return(:body => access_token_fixture)

      token = @client.login('test@test.com', '123')
      expect(token).to eq('token' => 'TestToken')

      expect(a_post("login").with(
               :body => { :email => 'test@test.com', :password => '123' }
             )).to have_been_made.once
    end

    it 'should raise an unauthorized error for bad credentials' do
      stub_post("login").to_return(:status => 401)

      expect do
        @client.login('test@test.com', '123')
      end.to raise_error(Gemfury::Unauthorized)
    end
  end

  describe '#get_access_token' do
    it 'should wrap #login with same args' do
      expect(@client).to receive(:login).
                           with('test@test.com', '123', { :as => 't123' }).
                           and_return('token' => 'TestToken')

      token = @client.get_access_token('test@test.com', '123', :as => 't123')
      expect(token).to eq('TestToken')
    end

    it 'should proxy #login exceptions' do
      expect do
        stub_post("login").to_return(:status => 401)
        @client.get_access_token('test@test.com', '123')
      end.to raise_error(Gemfury::Unauthorized)
    end
  end

  shared_examples 'API without authentication' do
    before { stub_api_method.to_return(:status => 401) }

    it 'should throw an authentication error without an api key' do
      expect do
        @client.user_api_key = nil
        send_api_request
      end.to raise_error(Gemfury::Unauthorized)
    end

    it 'should throw an authentication error on a bad key' do
      expect do
        @client.user_api_key = 'MyWrongApiKey'
        send_api_request
      end.to raise_error(Gemfury::Unauthorized)
    end
  end

  shared_examples 'graceful handler of errors' do
    it 'should raise NotFound error for a non-existent user' do
      stub_api_method.to_return(:status => 404)

      expect do
        send_api_request
      end.to raise_exception(Gemfury::NotFound)
    end

    it 'should throw a conflict error when resource is locked' do
      stub_api_method.to_return(:status => 409)

      expect do
        send_api_request
      end.to raise_exception(Gemfury::Conflict)
    end
  end

  describe '#account_info' do
    let(:stub_api_method)  { stub_get('users/me') }
    let(:send_api_request) { @client.account_info }

    it_should_behave_like 'API without authentication'

    describe 'while authenticated' do
      before do
        @client.user_api_key = 'MyAuthKey'
        stub_api_method.to_return(:body => fixture('me.json'))
      end

      it 'should return valid account info' do
        out = @client.account_info
        expect(out['username']).to eq('user1')
        expect(a_get("users/me")).to have_been_made
      end
    end
  end

  describe '#accounts' do
    let(:stub_api_method)  { stub_get('accounts') }
    let(:send_api_request) { @client.accounts }

    it_should_behave_like 'API without authentication'

    describe 'while authenticated' do
      before do
        stub_api_method.to_return(:body => fixture('accounts.json'))
        @client.user_api_key = 'MyAuthKey'
      end

      it 'should list accounts' do
        account_list = send_api_request
        first_account = account_list.first
        expect(a_get('accounts')).to have_been_made

        expect(account_list.size).to eq(1)
        expect(first_account['username']).to eq('user1')
        expect(first_account['type']).to eq('user')
        expect(first_account['viewer_permission']).to eq('OWNER')
      end
    end
  end

  describe '#push_gems' do
    let(:fixture_gem) do
      fixture('fury-0.0.2.gem')
    end

    let(:stub_api_method) do
      stub = stub_post('uploads', :endpoint => Gemfury.pushpoint)

      if @client.account
        stub.with(:query => { :as => @client.account })
      else
        stub
      end
    end

    let(:send_api_request) { @client.push_gem(fixture_gem) }

    it_should_behave_like 'API without authentication'

    shared_examples 'uploading gems' do
      it 'should upload successfully' do
        @client.push_gem(fixture_gem)
        post_opts = { :endpoint => Gemfury.pushpoint }

        if @client.account
          post_opts[:query] = { :as => @client.account }
        end

        expect(a_post('uploads', post_opts)).to have_been_made
      end
    end

    describe 'while authenticated' do
      before do
        @client.user_api_key = 'MyAuthKey'
        stub_api_method.to_return(:body => fixture('uploads.json'))
      end

      it_should_behave_like 'uploading gems'
    end

    describe 'while authenticated and using another account' do
      before do
        @client.account = 'username'
        @client.user_api_key = 'MyAuthKey'
        stub_api_method.to_return(:body => fixture('uploads.json'))
      end

      it_should_behave_like 'uploading gems'
    end
  end

  describe '#list' do
    let(:stub_api_method)  { stub_get('gems') }
    let(:send_api_request) { @client.list }

    it_should_behave_like 'API without authentication'

    describe 'while authenticated' do
      before do
        stub_api_method.to_return(:body => fixture('gems.json'))
        @client.user_api_key = 'MyAuthKey'
      end

      it 'should list uploaded gems' do
        gems_list = send_api_request
        expect(a_get("gems")).to have_been_made

        expect(gems_list.size).to eq(1)
        expect(gems_list.first['name']).to eq('example')
      end
    end
  end

  describe '#versions' do
    let(:stub_api_method)  { stub_get('gems/example/versions') }
    let(:send_api_request) { @client.versions('example') }

    it_should_behave_like 'API without authentication'

    describe 'while authenticated' do
      before do
        stub_api_method.to_return(:body => fixture('versions.json'))
        @client.user_api_key = 'MyAuthKey'
      end

      it 'should list gem versions' do
        versions = send_api_request
        expect(a_get("gems/example/versions")).to have_been_made

        expect(versions.size).to eq(5)
        expect(versions.first['slug']).to eq('example-0.0.1')
        expect(versions.first['created_by']['name']).to eq('user1')
      end
    end
  end

  describe '#yank_version' do
    let(:stub_api_method)  { stub_delete('gems/example/versions/0.0.1') }
    let(:send_api_request) { @client.yank_version('example', '0.0.1') }

    it_should_behave_like 'API without authentication'

    describe 'while authenticated' do
      before do
        @client.user_api_key = 'MyAuthKey'
        stub_api_method
      end

      it 'should delete selected package version' do
        send_api_request
        expect(a_delete("gems/example/versions/0.0.1")).to have_been_made
      end
    end
  end

  describe '#list_collaborators' do
    let(:stub_api_method)  { stub_get('collaborators') }
    let(:send_api_request) { @client.list_collaborators }

    it_should_behave_like 'API without authentication'

    describe 'while authenticated' do
      before do
        stub_api_method.to_return(:body => fixture('collaborators.json'))
        @client.user_api_key = 'MyAuthKey'
      end

      it 'should list account collaborators' do
        gems_list = send_api_request
        expect(a_get("collaborators")).to have_been_made

        expect(gems_list.size).to eq(2)
        expect(gems_list.first['username']).to eq('user2')
        expect(gems_list.first['permission']).to eq('push')
      end
    end
  end

  describe '#add_collaborators' do
    let(:stub_api_method)  { stub_put('collaborators/user1') }
    let(:send_api_request) { @client.add_collaborator('user1') }

    it_should_behave_like 'API without authentication'

    describe 'while authenticated' do
      before { @client.user_api_key = 'MyAuthKey' }

      it 'should add a collaborator' do
        stub_api_method
        send_api_request

        expect(a_put("collaborators/user1")).to have_been_made
      end

      it_should_behave_like 'graceful handler of errors'
    end
  end

  describe '#remove_collaborators' do
    let(:stub_api_method)  { stub_delete('collaborators/user1') }
    let(:send_api_request) { @client.remove_collaborator('user1') }

    it_should_behave_like 'API without authentication'

    describe 'while authenticated' do
      before { @client.user_api_key = 'MyAuthKey' }

      it 'should remove an existing collaborator' do
        stub_api_method
        send_api_request

        expect(a_delete("collaborators/user1")).to have_been_made
      end

      it_should_behave_like 'graceful handler of errors'
    end
  end

  describe '#git_repos' do
    let(:stub_api_method)  { stub_get('git/repos/me') }
    let(:send_api_request) { @client.git_repos }

    it_should_behave_like 'API without authentication'

    describe 'while authenticated' do
      before do
        stub_api_method.to_return(:body => fixture('repos.json'))
        @client.user_api_key = 'MyAuthKey'
      end

      it 'should list git repos' do
        repo_list = send_api_request['repos']
        expect(a_get("git/repos/me")).to have_been_made

        expect(repo_list.size).to eq(1)
        expect(repo_list.first['name']).to eq('example')
      end
    end
  end

  describe '#git_reset' do
    let(:stub_api_method)  { stub_delete('git/repos/me/example') }
    let(:send_api_request) { @client.git_reset('example') }

    it_should_behave_like 'API without authentication'

    describe 'while authenticated' do
      before do
        @client.user_api_key = 'MyAuthKey'
        stub_api_method
      end

      it_should_behave_like 'graceful handler of errors'

      it 'should yank specified git repo' do
        send_api_request
        expect(a_delete('git/repos/me/example')).to have_been_made
      end
    end
  end

  describe '#git_rename' do
    let(:stub_api_method)  { stub_patch('git/repos/me/example') }
    let(:send_api_request) { @client.git_update('example', {
      :repo => { :name => 'new_example' }
    }) }

    it_should_behave_like 'API without authentication'

    describe 'while authenticated' do
      before do
        @client.user_api_key = 'MyAuthKey'
        stub_api_method
      end

      it_should_behave_like 'graceful handler of errors'

      it 'should update specified git repo' do
        send_api_request
        expect(a_patch('git/repos/me/example')).to have_been_made
      end
    end
  end

  describe '#git_rebuild' do
    let(:stub_api_method)  { stub_post('git/repos/me/example/builds') }
    let(:send_api_request) { @client.git_rebuild('example', @params) }

    it_should_behave_like 'API without authentication'

    describe 'while authenticated' do
      before do
        @client.user_api_key = 'MyAuthKey'
        stub_api_method
      end

      it_should_behave_like 'graceful handler of errors'

      it 'should rebuild specified git repo' do
        send_api_request
        expect(a_post('git/repos/me/example/builds', {
                        :api_format => :text
        })).to have_been_made
      end

      context 'with specified revision' do
        before { @params = { :build => { :revision => 'tag-name' }} }
        it 'should rebuild git repo at specified revision' do
          send_api_request
          expect(a_post("git/repos/me/example/builds", {
                          :api_format => :text
                        }).with(:body => @params)).to have_been_made
        end
      end
    end
  end

  describe '#git_config' do
    let(:stub_api_method)  { stub_get('git/repos/me/example/config-vars') }
    let(:send_api_request) { @client.git_config('example') }

    it_should_behave_like 'API without authentication'

    describe 'while authenticated' do
      before do
        stub_api_method.to_return(:body => fixture('git_config.json'))
        @client.user_api_key = 'MyAuthKey'
      end

      it 'should list git repo config variables' do
        vars = send_api_request['config_vars']
        expect(a_get('git/repos/me/example/config-vars')).to have_been_made
        expect(vars).to eq({ "HELLO" => "WORLD", "SUPER" => "SECRET" })
      end
    end
  end

  describe '#git_config_update' do
    let(:update_payload)   { { "NEW" => "VAR"} }
    let(:stub_api_method)  { stub_patch('git/repos/me/example/config-vars') }
    let(:send_api_request) { @client.git_config_update('example', update_payload) }

    it_should_behave_like 'API without authentication'

    describe 'while authenticated' do
      before do
        stub_api_method.to_return(:body => fixture('git_config.json'))
        @client.user_api_key = 'MyAuthKey'
      end

      it 'should list git repo config variables' do
        vars = send_api_request['config_vars']
        body = Faraday::NestedParamsEncoder.encode('config_vars' => update_payload)
        expect(a_patch('git/repos/me/example/config-vars', :body => body)).to have_been_made
        expect(vars).to eq({ "HELLO" => "WORLD", "SUPER" => "SECRET" })
      end
    end
  end

  def access_token_fixture
    ::MultiJson.encode(:token => 'TestToken')
  end
end
