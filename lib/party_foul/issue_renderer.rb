class PartyFoul::IssueRenderer
  attr_accessor :exception, :env

  def initialize(exception, env)
    self.exception = exception
    self.env       = env
  end

  def title
    line = exception.backtrace.select {|p| p =~ /#{app_root}/ }.first
    name_and_number = extract_file_name_and_line_number(line)[1]
    "#{exception} - #{name_and_number}"
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
        "<a href='#{PartyFoul.repo_url}/tree/master/#{matches[2]}#L#{matches[3]}'>#{line}</a>"
      else
        line
      end
    end.join("\n")
  end

  def fingerprint
    Digest::SHA1.hexdigest(issue_title)
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
    if env["action_dispatch.parameter_filter"]
      parameter_filter = ActionDispatch::Http::ParameterFilter.new(env["action_dispatch.parameter_filter"])
      parameter_filter.filter(env['action_dispatch.request.path_parameters'])
    else
      env['QUERY_STRING']
    end
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
    if defined?(Rails)
      Rails.root
    else
      Dir.pwd
    end
  end

  def file_and_line_regex
    /#{app_root}\/((.+?):(\d+))/
  end

  def extract_file_name_and_line_number(backtrace_line)
    backtrace_line.match(file_and_line_regex)
  end
end
