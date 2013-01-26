require 'test_helper'

describe 'Party Foul Confg' do

  after do
    clean_up_party
  end

  it 'sets the proper config variables' do
    PartyFoul.configure do |config|
      config.ignored_exceptions = ['StandardError']
      config.oauth_token        = 'test_token'
      config.web_url            = 'http://example.com'
      config.endpoint           = 'http://api.example.com'
      config.owner              = 'test_owner'
      config.repo               = 'test_repo'
    end

    PartyFoul.ignored_exceptions.must_equal ['StandardError']
    PartyFoul.github.must_be_instance_of Github::Client
    PartyFoul.github.oauth_token.must_equal 'test_token'
    PartyFoul.github.endpoint.must_equal 'http://api.example.com'
    PartyFoul.owner.must_equal 'test_owner'
    PartyFoul.repo.must_equal 'test_repo'
    PartyFoul.repo_url.must_equal 'http://example.com/test_owner/test_repo'
  end
end
