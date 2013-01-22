class PartyFoul::ExceptionHandler
  attr_accessor :exception, :env

  def self.handle(exception, env)
    handler = self.new(exception, env)
    handler.run
  end

  def initialize(exception, env)
    self.exception = exception
    self.env       = env
  end

  def run
    if issue = find_issue
      update_issue(issue)
    else
      create_issue
    end
  end

  def find_issue
    unless issue = PartyFoul.github.search.issues(owner: PartyFoul.owner, repo: PartyFoul.repo, state: 'open', keyword: fingerprint).issues.first
      issue = PartyFoul.github.search.issues(owner: PartyFoul.owner, repo: PartyFoul.repo, state: 'closed', keyword: fingerprint).issues.first
    end

    issue
  end

  def stack_trace
    exception.backtrace.map do |line|
      if matches = extract_file_name_and_line_number(line)
        "<a href='../tree/master/#{matches[2]}#L#{matches[3]}'>#{line}</a>"
      else
        line
      end
    end.join("\n ")
  end

  def create_issue
    PartyFoul.github.issues.create(PartyFoul.owner, PartyFoul.repo, title: issue_title, body: issue_body, labels: ['bug'])
  end

  def update_issue(issue)
    params = {body: update_body(issue['body']), state: 'open'}

    if issue['state'] == 'closed'
      params[:labels] = ['bug', 'regression']
    end

    PartyFoul.github.issues.edit(PartyFoul.owner, PartyFoul.repo, issue['number'], params)
  end

  def issue_title
    line = exception.backtrace.select {|p| p =~ /#{app_root}/ }.first
    name_and_number = extract_file_name_and_line_number(line)[1]
    "#{exception} - #{name_and_number}"
  end

  def fingerprint
    Digest::SHA1.hexdigest(issue_title)
  end

  def update_body(body)
    begin
      current_count = body.match(/<th>Count<\/th><td>(\d+)<\/td>/)[1].to_i
      body.sub!("<th>Count</th><td>#{current_count}</td>", "<th>Count</th><td>#{current_count + 1}</td>")
      body.sub!(/<th>Last Occurance<\/th><td>.+<\/td>/, "<th>Last Occurance</th><td>#{Time.now}</td>")
      body
    rescue
      issue_body
    end
  end

  def params
    env['action_dispatch.request.path_parameters'] || env['QUERY_STRING']
  end

  def issue_body
    <<-BODY
<table>
<tr><th>Fingerprint</th><td>#{fingerprint}</td><tr>
<tr><th>Count</th><td>1</td></tr>
<tr><th>Last Occurance</th><td>#{Time.now}</td></tr>
<tr><th>Params</th><td>#{params}</td></tr>
<tr><th>Exception</th><td>#{exception}</td></tr>
</table>

## Stack Trace
<pre>#{stack_trace}</pre>
    BODY
  end

  private

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
