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

# require 'oauth2'

# module PartyFoul
  # class ExceptionHandler
    # def self.handle(exception, env)
      # return # Need to pull config from yaml file
      # client = OAuth2::Client.new ClientId, ClientSecret, :site => 'https://api.github.com'

      # access_token = OAuth2::AccessToken.new client, AccessToken
      # debugger

      # issue_body = <<-ISSUE
# # Path

# #{url_string(env)}

# # Params

# ```
# #{params_string(env)}
# ```

# # Backtrace

# #{linked_backtrace(exception.backtrace).join "\n"}

# ISSUE
      # line = exception.backtrace.select {|p| p =~ /#{Rails.root}/ }.first
      # name_and_number = extract_file_name_and_line_number(line)[1]
      # access_token.post "/repos/#{Owner}/#{Repo}/issues", :body => { :title => "#{exception.to_s} - #{name_and_number}", :body => issue_body }.to_json

    # end

    # def self.url_string(env)
      # uri = URI::HTTP.new env['rack.url_scheme'], nil, env['SERVER_NAME'], env['SERVER_PORT'], nil, env['REQUEST_PATH'], nil, env['QUERY_STRING'], nil

      # uri.to_s
    # end

    # def self.params_string(env)
      # params = env['action_dispatch.request.parameters']

      # params.map { |k,v| "#{k}=#{v}" }.join "\n"
    # end

    # def self.linked_backtrace(backtrace)
      # backtrace.map do |line|
        # if matches = extract_file_name_and_line_number(line)
          # " * [#{line}](../tree/master/#{matches[2]}#L#{matches[3]}) "
        # else
          # " * #{line} "
        # end
      # end
    # end

    # def self.file_and_line_regex
      # /#{Rails.root}\/((.+?):(\d+))/
    # end

    # def self.extract_file_name_and_line_number(backtrace_line)
      # backtrace_line.match(file_and_line_regex)
    # end
  # end
# end
