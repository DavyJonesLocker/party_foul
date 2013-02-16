require 'test_helper'

describe 'Party Foul Confg' do

  after do
    clean_up_party
  end

  it 'sets the proper config variables' do
    PartyFoul.configure do |config|
      config.blacklisted_exceptions = ['StandardError']
      config.oauth_token        = 'test_token'
      config.web_url            = 'http://example.com'
      config.endpoint           = 'http://api.example.com'
      config.owner              = 'test_owner'
      config.repo               = 'test_repo'
      config.branch             = 'master'
      config.comment_limit      = 10
    end

    PartyFoul.blacklisted_exceptions.must_equal ['StandardError']
    PartyFoul.github.must_be_instance_of Github::Client
    PartyFoul.github.oauth_token.must_equal 'test_token'
    PartyFoul.github.endpoint.must_equal 'http://api.example.com'
    PartyFoul.owner.must_equal 'test_owner'
    PartyFoul.repo.must_equal 'test_repo'
    PartyFoul.repo_url.must_equal 'http://example.com/test_owner/test_repo'
    PartyFoul.branch.must_equal 'master'
    PartyFoul.comment_limit.must_equal 10
  end

  it 'has default values' do
    PartyFoul.web_url.must_equal 'https://github.com'
    PartyFoul.branch.must_equal  'master'
  end
end
