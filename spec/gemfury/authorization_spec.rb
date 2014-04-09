require 'spec_helper'

describe Gemfury::Command::Authorization do
  class AuthorizedThing
    include Gemfury::Command::Authorization

    def netrc_host
      'host'
    end
  end

  let(:netrc) { double('netrc') }

  before do
    subject.stub(:netrc_conf).and_return(netrc)
  end

  context 'when ~/.netrc has an email address for login' do
    subject { AuthorizedThing.new }

    before do
      netrc.stub(:[]).and_return(%w(useraccount@example.com DEADBEEF))
    end

    it 'should NOT set @account when loading credentials' do
      subject.send(:load_credentials!)
      subject.instance_variable_get(:@account).should be_nil
    end
  end

  context 'when ~/.netrc has a user account for login' do
    subject { AuthorizedThing.new }

    before do
      netrc.stub(:[]).and_return(%w(useraccount DEADBEEF))
    end

    it 'should set @account when loading credentials' do
      subject.send(:load_credentials!)
      subject.instance_variable_get(:@account).should eq('useraccount')
    end
  end


end
