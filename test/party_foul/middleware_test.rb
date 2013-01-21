require 'test_helper'

describe 'Party Foul Middleware' do
  include Rack::Test::Methods

  def app
    Rack::Builder.new {
      map '/' do
        use PartyFoul::Middleware
        run lambda { |env| raise StandardError }
      end
    }
  end

  before do
    PartyFoul.config do |config|
      config.oauth_token = 'abcdefg1234567890'
      config.owner       = 'test_owner'
      config.repo        = 'test_repo'
    end
    PartyFoul.github.issues.stubs(:create)
    PartyFoul::ExceptionHandler.any_instance.stubs(:issue_title).returns('Test Title')
  end

  context 'when error is new' do
    it 'will open a new error on Github' do
      PartyFoul::ExceptionHandler.any_instance.stubs(:issue_body).returns('Test Body')
      PartyFoul.github.search.stubs(:issues).with(owner: 'test_owner', repo: 'test_repo', keyword: 'Test Title', state: 'open').returns(Hashie::Mash.new(issues: []))
      PartyFoul.github.search.stubs(:issues).with(owner: 'test_owner', repo: 'test_repo', keyword: 'Test Title', state: 'closed').returns(Hashie::Mash.new(issues: []))
      PartyFoul.github.issues.expects(:create).with('test_owner', 'test_repo', title: 'Test Title', body: 'Test Body', :labels => ['bug'])
      get '/' rescue nil
    end
  end

  context 'when error is not new' do
    before do
      PartyFoul::ExceptionHandler.any_instance.stubs(:update_body).returns('New Body')
    end

    context 'and open' do
      it 'will open the count on the body' do
        PartyFoul.github.search.stubs(:issues).with(owner: 'test_owner', repo: 'test_repo', keyword: 'Test Title', state: 'open').returns(Hashie::Mash.new(issues: [{title: 'Test Title', body: 'Test Body', status: 'open', number: 1}]))
        PartyFoul.github.issues.expects(:edit).with('test_owner', 'test_repo', 1, body: 'New Body', state: 'open')
        get '/' rescue nil
      end
    end

    context 'and closed' do
      it 'will update the count on the body and re-open the issue' do
        PartyFoul.github.search.stubs(:issues).with(owner: 'test_owner', repo: 'test_repo', keyword: 'Test Title', state: 'open').returns(Hashie::Mash.new(issues: []))
        PartyFoul.github.search.stubs(:issues).with(owner: 'test_owner', repo: 'test_repo', keyword: 'Test Title', state: 'closed').returns(Hashie::Mash.new(issues: [{title: 'Test Title', body: 'Test Body', status: 'closed', number: 1}]))
        PartyFoul.github.issues.expects(:edit).with('test_owner', 'test_repo', 1, body: 'New Body', state: 'open')
        get '/' rescue nil
      end
    end
  end
end
