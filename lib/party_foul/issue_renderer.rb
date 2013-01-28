class PartyFoul::IssueRenderer
  attr_accessor :exception, :env, :sha

  def initialize(exception, env)
    self.exception = exception
    self.env       = env
  end

  def title
    raise NotImplementedError
  end

  def body
    compile_template(PartyFoul.issue_template)
  end

  def comment
    compile_template(PartyFoul.comment_template)
  end

  def stack_trace
    exception.backtrace.map do |line|
      if matches = extract_file_name_and_line_number(line)
        "<a href='#{PartyFoul.repo_url}/blob/#{sha}/#{matches[2]}#L#{matches[3]}'>#{line}</a>"
      else
        line
      end
    end.join("\n")
  end

  def fingerprint
    Digest::SHA1.hexdigest(title)
  end

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

  def params
    raise NotImplementedError
  end

  def occurred_at
    Time.now.strftime('%B %d, %Y %H:%M:%S %z')
  end

  def ip_address
    env['REMOTE_ADDR']
  end

  def session
    env['rack.session']
  end

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
