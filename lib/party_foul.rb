require 'github_api'

module PartyFoul
  class << self
    attr_accessor :github, :oauth_token, :endpoint, :owner, :repo, :blacklisted_exceptions, :processor, :web_url, :branch, :whitelisted_rack_variables, :additional_labels
  end

  def self.whitelisted_rack_variables
    @whitelisted_rack_variables ||= %w{GATEWAY_INTERFACE PATH_INFO REMOTE_ADDR REMOTE_HOST REQUEST_METHOD REQUEST_URI SERVER_NAME SERVER_PORT SERVER_PROTOCOL SERVER_SOFTWARE HTTP_HOST HTTP_CONNECTION HTTP_CACHE_CONTROL HTTP_ACCEPT HTTP_USER_AGENT HTTP_ACCEPT_ENCODING HTTP_ACCEPT_LANGUAGE HTTP_ACCEPT_CHARSET rack.version rack.input rack.errors rack.multithread rack.multiprocess rack.run_once rack.url_scheme HTTP_VERSION REQUEST_PATH ORIGINAL_FULLPATH action_dispatch.routes action_dispatch.parameter_filter action_dispatch.secret_token action_dispatch.show_exceptions action_dispatch.show_detailed_exceptions action_dispatch.logger action_dispatch.backtrace_cleaner action_dispatch.request_id action_dispatch.remote_ip rack.session rack.session.options rack.request.cookie_hash rack.request.cookie_string action_dispatch.cookies action_dispatch.request.unsigned_session_cookie action_dispatch.request.path_parameters action_controller.instance action_dispatch.request.request_parameters rack.request.query_string rack.request.query_hash action_dispatch.request.query_parameters action_dispatch.request.parameters action_dispatch.request.formats}
  end

  # The git branch that is used for linking in the stack trace
  #
  # @return [String] Defaults to 'master' if not set
  def self.branch
    @branch ||= 'master'
  end

  # The web url for Github. This is only interesting for Enterprise
  # users
  #
  # @return [String] Defaults to 'https://github.com' if not set
  def self.web_url
    @web_url ||= 'https://github.com'
  end

  # The api endpoint for Github. This is only interesting for Enterprise
  # users
  #
  # @return [String] Defaults to 'https://api.github.com' if not set
  def self.endpoint
    @endpoint ||= 'https://api.github.com'
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

  # The url of the repository. Built using the {.web_url}, {.owner}, and {.repo}
  # values
  #
  # @return [String]
  def self.repo_url
    "#{web_url}/#{owner}/#{repo}"
  end

  # The configure block for PartyFoul. Use to initialize settings
  #
  #     PartyFoul.configure do |config|
  #       config.owner 'dockyard'
  #       config.repo  'test_app'
  #       config.oauth_token = ENV['oauth_token']
  #     end
  #
  # Will also setup for Github api connections
  #
  # @param [Block]
  def self.configure(&block)
    yield self
    self.github ||= Github.new oauth_token: oauth_token, endpoint: endpoint
  end
end

require 'party_foul/exception_handler'
require 'party_foul/rackless_exception_handler'
require 'party_foul/issue_renderers'
require 'party_foul/middleware'
require 'party_foul/processors'
