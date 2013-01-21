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
    issue = nil

    unless issue = PartyFoul.github.search.issues(owner: PartyFoul.owner, repo: PartyFoul.repo, state: 'open', keyword: issue_title).issues.first
      issue = PartyFoul.github.search.issues(owner: PartyFoul.owner, repo: PartyFoul.repo, state: 'closed', keyword: issue_title).issues.first
    end

    issue
  end

  def create_issue
    PartyFoul.github.issues.create(PartyFoul.owner, PartyFoul.repo, title: issue_title, body: issue_body, labels: ['bug'])
  end

  def update_issue(issue)
    PartyFoul.github.issues.edit(PartyFoul.owner, PartyFoul.repo, issue.number, body: update_body(issue.body), state: 'open')
  end

  def issue_title
    line = exception.backtrace.select {|p| p =~ /#{app_root}/ }.first
    name_and_number = extract_file_name_and_line_number(line)[1]
    "#{exception} - #{name_and_number}"
  end

  def update_body(body)
    begin
      current_count = body.match(/^Count: (\d+)/)[1].to_i
      body.sub!("Count: #{current_count}", "Count: #{current_count + 1}")
      body.sub!(/Last Occurance: .+/, "Last Occurance: #{Time.now}")
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
Count: 1
Last Occurance: #{Time.now}
Params: `#{params}`
Exception: `#{exception}`
Stack Trace:
```
#{stack_trace}
```
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
