require 'test_helper'

describe 'Party Foul Middleware' do
  include Rack::Test::Methods

  after do
    clean_up_party
  end

  def error_to_raise
    Exception
  end

  def app
    _self = self
    Rack::Builder.new {
      map '/' do
        use PartyFoul::Middleware
        run lambda { |env| raise _self.error_to_raise }
      end
    }
  end

  before do
    PartyFoul.configure do |config|
      config.oauth_token = 'abcdefg1234567890'
      config.owner       = 'test_owner'
      config.repo        = 'test_repo'
    end
    PartyFoul.github.stubs(:issues).returns(mock('Issues'))
    PartyFoul.github.stubs(:search).returns(mock('Search'))
    PartyFoul.github.issues.stubs(:create)
    PartyFoul::ExceptionHandler.any_instance.stubs(:issue_title).returns('Test Title')
    PartyFoul::ExceptionHandler.any_instance.stubs(:fingerprint).returns('test_fingerprint')
  end

  context 'when error is new' do
    it 'will open a new error on Github' do
      PartyFoul::ExceptionHandler.any_instance.stubs(:issue_body).returns('Test Body')
      PartyFoul.github.search.stubs(:issues).with(owner: 'test_owner', repo: 'test_repo', keyword: 'test_fingerprint', state: 'open').returns(Hashie::Mash.new(issues: []))
      PartyFoul.github.search.stubs(:issues).with(owner: 'test_owner', repo: 'test_repo', keyword: 'test_fingerprint', state: 'closed').returns(Hashie::Mash.new(issues: []))
      PartyFoul.github.issues.expects(:create).with('test_owner', 'test_repo', title: 'Test Title', body: 'Test Body', :labels => ['bug'])
      lambda {
        get '/'
      }.must_raise(Exception)
    end
  end

  context 'when error is not new' do
    before do
      PartyFoul::ExceptionHandler.any_instance.stubs(:update_body).returns('New Body')
    end

    context 'and open' do
      it 'will update the issue' do
        PartyFoul.github.search.stubs(:issues).with(owner: 'test_owner', repo: 'test_repo', keyword: 'test_fingerprint', state: 'open').returns(Hashie::Mash.new(issues: [{title: 'Test Title', body: 'Test Body', state: 'open', number: 1}]))
        PartyFoul.github.issues.expects(:edit).with('test_owner', 'test_repo', 1, body: 'New Body', state: 'open')
        lambda {
          get '/'
        }.must_raise(Exception)
      end
    end

    context 'and closed' do
      it 'will update the count on the body and re-open the issue' do
        PartyFoul.github.search.stubs(:issues).with(owner: 'test_owner', repo: 'test_repo', keyword: 'test_fingerprint', state: 'open').returns(Hashie::Mash.new(issues: []))
        PartyFoul.github.search.stubs(:issues).with(owner: 'test_owner', repo: 'test_repo', keyword: 'test_fingerprint', state: 'closed').returns(Hashie::Mash.new(issues: [{title: 'Test Title', body: 'Test Body', state: 'closed', number: 1}]))
        PartyFoul.github.issues.expects(:edit).with('test_owner', 'test_repo', 1, body: 'New Body', state: 'open', labels: ['bug', 'regression'])
        lambda {
          get '/'
        }.must_raise(Exception)
      end
    end
  end

  context 'filtering based upon exception' do
    before do
      PartyFoul.ignored_exceptions = ['StandardError']
      self.stubs(:error_to_raise).returns(StandardError)
    end

    it 'does not handle exception' do
      PartyFoul::ExceptionHandler.any_instance.stubs(:issue_body).returns('Test Body')
      PartyFoul.github.search.stubs(:issues).with(owner: 'test_owner', repo: 'test_repo', keyword: 'test_fingerprint', state: 'open').returns(Hashie::Mash.new(issues: []))
      PartyFoul.github.search.stubs(:issues).with(owner: 'test_owner', repo: 'test_repo', keyword: 'test_fingerprint', state: 'closed').returns(Hashie::Mash.new(issues: []))
      PartyFoul.github.issues.expects(:create).never
      lambda {
        get '/'
      }.must_raise(StandardError)
    end
  end
end
