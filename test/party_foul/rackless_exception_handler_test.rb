require 'test_helper'

describe 'Party Foul Rackless Exception Handler' do
  before do
    PartyFoul.configure do |config|
      config.oauth_token = 'abcdefg1234567890'
      config.owner       = 'test_owner'
      config.repo        = 'test_repo'
    end
  end

  describe '#handle' do
    it 'will call run on itself' do
      PartyFoul::RacklessExceptionHandler.any_instance.expects(:run)
      PartyFoul::RacklessExceptionHandler.handle(nil, {})
    end

    it 'should pass parameters required by the renderer to the initializer' do
      params = {:class => Object, :method => :to_s, :params => {:one => "One", :two => "Two"}}
      expected_exception_handler = PartyFoul::RacklessExceptionHandler.new(nil, params)
      expected_exception_handler.expects(:run)
      PartyFoul::RacklessExceptionHandler.expects(:new).with(nil, params).returns(expected_exception_handler)
      PartyFoul::RacklessExceptionHandler.handle(nil, params)
    end

    context 'filtering based upon exception' do
      before do
        PartyFoul.blacklisted_exceptions = ['StandardError']
      end

      it 'does not handle exception' do
        PartyFoul::RacklessExceptionHandler.expects(:new).never

        PartyFoul::RacklessExceptionHandler.handle StandardError.new, {}
      end
    end
  end

  describe '#initialize' do
    it 'should use PartyFoul::IssueRenderers::Rackless for rendering issues' do
      issue_renderer = PartyFoul::RacklessExceptionHandler.new(nil, {}).rendered_issue
      assert_kind_of(PartyFoul::IssueRenderers::Rackless, issue_renderer)
    end
  end
end
