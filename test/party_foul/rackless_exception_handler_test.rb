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
  end

  describe '#initialize' do
    it 'should use PartyFoul::IssueRenderers::Rackless for rendering issues' do
      issue_renderer = PartyFoul::RacklessExceptionHandler.new(nil, {}).rendered_issue
      assert_kind_of(PartyFoul::IssueRenderers::Rackless, issue_renderer)
    end
  end
end
