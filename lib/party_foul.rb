require 'github_api'

module PartyFoul
  class << self
    attr_accessor :github, :oauth_token, :endpoint, :owner, :repo,
      :ignored_exceptions, :processor, :issue_template,
      :comment_template, :filtered_http_headers, :web_url
  end

  def self.web_url
    @web_url ||= 'https://github.com'
  end

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

  def self.comment_template
    @comment_template ||=
    <<-TEMPLATE
<table>
<tr><th>Occurred at</th><td>:occurred_at</td></tr>
<tr><th>Params</th><td>:params</td></tr>
<tr><th>IP Address</th><td>:ip_address</td></tr>
<tr><th>Session</th><td>:session</td></tr>
<tr><th>HTTP Headers</th><td>:http_headers</td></tr>
</table>
    TEMPLATE
  end

  def self.ignored_exceptions
    @ignored_exceptions || []
  end

  def self.repo_url
    "#{web_url}/#{owner}/#{repo}"
  end

  def self.configure(&block)
    yield self
    self.processor ||= PartyFoul::Processors::Sync
    _self = self
    self.github ||= Github.new do |config|
      %w{endpoint oauth_token}.each do |option|
        config.send("#{option}=", _self.send(option)) if !_self.send(option).nil?
      end
    end
  end
end

require 'party_foul/exception_handler'
require 'party_foul/issue_renderer'
require 'party_foul/middleware'
require 'party_foul/processors'
