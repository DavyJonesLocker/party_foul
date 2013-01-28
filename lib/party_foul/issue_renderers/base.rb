class PartyFoul::IssueRenderers::Base
  attr_accessor :exception, :env, :sha

  # A new renderer instance for Githug issues
  #
  # @param [Exception, Hash]
  def initialize(exception, env)
    self.exception = exception
    self.env       = env
  end

  # Derived title of the issue. Must be implemented by the adapter class
  #
  # @return [NotImplementedError]
  def title
    raise NotImplementedError
  end

  # Will compile the template for an issue body as defined in
  # {PartyFoul.issue_template}
  #
  # @return [String]
  def body
    compile_template(PartyFoul.issue_template)
  end

  # Will compile the template for a comment body as defined in
  # {PartyFoul.comment_template}
  def comment
    compile_template(PartyFoul.comment_template)
  end

  # Compiles the stack trace for use in the issue body. Lines in the
  # stack trace that are part of the application will be rendered as
  # links to the relative file and line on Github based upon
  # {PartyFoul.web_url}, {PartyFoul.owner}, {PartyFoul.repo}, and
  # {PartyFoul.branch}. The branch will be used at the time the
  # exception happens to grab the SHA for that branch at that time for
  # the purpose of linking.
  #
  # @return [String]
  def stack_trace
    exception.backtrace.map do |line|
      if matches = extract_file_name_and_line_number(line)
        "<a href='#{PartyFoul.repo_url}/blob/#{sha}/#{matches[2]}#L#{matches[3]}'>#{line}</a>"
      else
        line
      end
    end.join("\n")
  end

  # A SHA1 hex digested representation of the title. The fingerprint is
  # used to create a unique value in the issue body. This value is used
  # for seraching when matching issues happen again in the future.
  #
  # @return [String]
  def fingerprint
    Digest::SHA1.hexdigest(title)
  end

  # Will update the issue body. The count and the time stamp will both
  # be updated. If the format of the issue body fails to match for
  # whatever reason the issue body will be reset.
  #
  # @return [String]
  def update_body(old_body)
    begin
      current_count = old_body.match(/<th>Count<\/th><td>(\d+)<\/td>/)[1].to_i
      old_body.sub!("<th>Count</th><td>#{current_count}</td>", "<th>Count</th><td>#{current_count + 1}</td>")
      old_body.sub!(/<th>Last Occurance<\/th><td>.+<\/td>/, "<th>Last Occurance</th><td>#{occurred_at}</td>")
      old_body
    rescue
      self.body
    end
  end

  # The params hash at the time the exception occurred. This method is
  # overriden for each framework adapter. It should return a hash.
  #
  # @return [NotImplementedError]
  def params
    raise NotImplementedError
  end

  # The timestamp when the exception occurred.
  #
  # @return [String]
  def occurred_at
    Time.now.strftime('%B %d, %Y %H:%M:%S %z')
  end

  # IP address of the client who triggered the exception
  #
  # @return [String]
  def ip_address
    env['REMOTE_ADDR']
  end

  # The session hash for the client at the time of the exception
  #
  # @return [Hash]
  def session
    env['rack.session']
  end

  # HTTP Headers hash from the request. Headers can be filtered out by
  # adding matching key names to {PartyFoul.filtered_http_headers}
  #
  # @return [Hash]
  def http_headers
    env.keys.select { |key| key =~ /^HTTP_(\w+)/ && !(PartyFoul.filtered_http_headers || []).include?($1.split('_').map(&:capitalize).join('-')) }.sort.inject({}) do |hash, key|
      hash[key.split('HTTP_').last.split('_').map(&:capitalize).join('-')] = env[key]
      hash
    end
  end

  def compile_template(template)
    template.gsub(/:\w+/) do |method|
      value = self.send(method.split(':').last)
      if value.kind_of?(Hash)
        hash_as_table(value)
      else
        value
      end
    end
  end

  private

  def hash_as_table(value)
    "<table>#{value.map {|key, value| "<tr><th>#{key}</th><td>#{value}</td></tr>"}.join}</table>"
  end

  def app_root
    Dir.pwd
  end

  def extract_file_name_and_line_number(backtrace_line)
    backtrace_line.match(/#{app_root}\/((.+?):(\d+))/)
  end
end

require 'party_foul/issue_renderers/rack'
require 'party_foul/issue_renderers/rails'
