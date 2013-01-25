require 'github_api'

module PartyFoul
  class << self
    attr_accessor :github, :oauth_token, :endpoint, :owner, :repo, :ignored_exceptions, :adapter
  end

  def self.ignored_exceptions
    @ignored_exceptions || []
  end

  def self.configure(&block)
    yield self
    self.adapter ||= SyncAdapter
    _self = self
    self.github ||= Github.new do |config|
      %w{endpoint oauth_token}.each do |option|
        config.send("#{option}=", _self.send(option)) if !_self.send(option).nil?
      end
    end
  end
end

require 'party_foul/exception_handler'
require 'party_foul/middleware'
require 'party_foul/sync_adapter'
