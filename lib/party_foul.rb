require 'octokit'

module PartyFoul
  class << self
    attr_accessor :github, :oauth_token, :owner, :repo, :additional_labels, :comment_limit, :title_prefix
    attr_writer :branch, :web_url, :api_endpoint, :processor, :blacklisted_exceptions
  end

  # The git branch that is used for linking in the stack trace
  #
  # @return [String] Defaults to 'master' if not set
  def self.branch
    @branch ||= 'master'
  end

  # The web url for GitHub. This is only interesting for Enterprise
  # users
  #
  # @return [String] Defaults to 'https://github.com' if not set
  def self.web_url
    @web_url ||= 'https://github.com'
  end

  # The api endpoint for GitHub. This is only interesting for Enterprise
  # users
  #
  # @return [String] Defaults to 'https://api.github.com' if not set
  def self.api_endpoint
    @api_endpoint ||= 'https://api.github.com'
  end

  # The processor to be used when handling the exception. Defaults to a
  # synchrons processor
  #
  # @return [Class] Defaults to 'PartyFoul::Processors:Sync
  def self.processor
    @processor ||= PartyFoul::Processors::Sync
  end

  # The collection of exceptions that should not be captured. Members of
  # the collection must be string representations of the exception. For
  # example:
  #
  #     # This is good
  #     ['ActiveRecord::RecordNotFound']
  #
  #     # This is not
  #     [ActiveRecord::RecordNotFound]
  #
  # @return [Array]
  def self.blacklisted_exceptions
    @blacklisted_exceptions || []
  end

  # The GitHub path to the repo
  # Built using {.owner} and {.repo}
  #
  # @return [String]
  def self.repo_path
    "#{owner}/#{repo}"
  end

  # The url of the repository. Built using the {.web_url} and {.repo_path}
  # values
  #
  # @return [String]
  def self.repo_url
    "#{web_url}/#{repo_path}"
  end

  # The configure block for PartyFoul. Use to initialize settings
  #
  #     PartyFoul.configure do |config|
  #       config.owner 'dockyard'
  #       config.repo  'test_app'
  #       config.oauth_token = ENV['oauth_token']
  #     end
  #
  # Will also setup for GitHub api connections
  #
  # @param [Block]
  def self.configure
    yield self
    self.github = Octokit::Client.new access_token: oauth_token, api_endpoint: api_endpoint
  end
end

require 'party_foul/exception_handler'
require 'party_foul/rackless_exception_handler'
require 'party_foul/issue_renderers'
require 'party_foul/middleware'
require 'party_foul/processors'
