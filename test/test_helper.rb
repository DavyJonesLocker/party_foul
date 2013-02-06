require 'bundler/setup'

if defined?(M)
  require 'minitest/spec'
else
  require 'minitest/autorun'
end
begin
  require 'debugger'
rescue LoadError
end
require 'rack/test'
require 'mocha/setup'
require 'party_foul'

class MiniTest::Spec
  class << self
    alias :context :describe
  end
end

module MiniTest::Expectations
  infect_an_assertion :assert_received, :must_have_received
end

def clean_up_party
  %w{github oauth_token endpoint owner repo blacklisted_exceptions processor web_url branch additional_labels}.each do |attr|
    PartyFoul.send("#{attr}=", nil)
  end
end
