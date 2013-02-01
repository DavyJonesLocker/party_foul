require 'github_api'

module PartyFoul
  class << self
    attr_accessor :github, :oauth_token, :endpoint, :owner, :repo,
      :blacklisted_exceptions, :processor, :issue_template,
      :comment_template, :blacklisted_headers, :web_url, :branch
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

  # The template used for rendering the body of a new issue
  #
  # @return [String]
  def self.issue_template
    @issue_template ||=
    <<-TEMPLATE
<table>
<tr><th>Exception</th><td>:exception</td></tr>
<tr><th>Count</th><td>1</td></tr>
<tr><th>Last Occurance</th><td>:occurred_at</td></tr>
</table>

## Stack Trace
<pre>:stack_trace</pre>
Fingerprint: `:fingerprint`
    TEMPLATE
  end

  # The template used for rendering the body of a new comment
  #
  # @return [String]
  def self.comment_template
    @comment_template ||=
    <<-TEMPLATE
<table>
<tr><th>Occurred at</th><td>:occurred_at</td></tr>
<tr><th>Params</th><td>:params</td></tr>
<tr><th>Session</th><td>:session</td></tr>
<tr><th>HTTP Headers</th><td>:http_headers</td></tr>
</table>
    TEMPLATE
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
