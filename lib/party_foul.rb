require 'active_support'
require 'github_api'

module PartyFoul
  extend ActiveSupport::Autoload

  autoload :Middleware
  autoload :ExceptionHandler

  class << self
    attr_accessor :github, :oauth_token, :endpoint, :owner, :repo, :ignored_exceptions
  end

  def self.ignored_exceptions
    @ignored_exceptions || []
  end

  def self.configure(&block)
    yield self
    _self = self
    self.github ||= Github.new do |config|
      %w{endpoint oauth_token}.each do |option|
        config.send("#{option}=", _self.send(option)) if !_self.send(option).nil?
      end
    end
  end
end
