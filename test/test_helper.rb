require 'bundler/setup'

if defined?(M)
  require 'minitest/spec'
else
  require 'minitest/autorun'
end
begin
  require 'byebug'
rescue LoadError
end
require 'rack/test'
require 'mocha/setup'
require 'active_support'
require 'party_foul'

ActiveSupport.test_order = :random

class MiniTest::Spec
  class << self
    alias :context :describe
  end
end

module MiniTest::Expectations
  infect_an_assertion :assert_received, :must_have_received
end

def clean_up_party
  %w{github oauth_token api_endpoint owner repo blacklisted_exceptions processor web_url branch additional_labels comment_limit}.each do |attr|
    PartyFoul.send("#{attr}=", nil)
  end
end

def sawyer_resource(attrs)
  agent = Sawyer::Agent.new(PartyFoul.api_endpoint)
  Sawyer::Resource.new(agent, attrs)
end

def no_search_results
  sawyer_resource(total_count: 0, incomplete_results: false, items: [])
end
