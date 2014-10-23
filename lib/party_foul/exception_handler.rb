class PartyFoul::ExceptionHandler
  attr_accessor :rendered_issue

  # This handler will pass the exception and env from Rack off to a processor.
  # The default PartyFoul processor will work synchronously. Processor adapters can be written
  # to push this logic to a background job if desired.
  #
  # @param [Exception, Hash]
  def self.handle(exception, env)
    PartyFoul.processor.handle(exception, clean_env(env))
  end

  # Makes an attempt to determine what framework is being used and will use the proper
  # IssueRenderer.
  #
  # @param [Exception, Hash]
  def initialize(exception, env)
    renderer_klass = if defined?(Rails)
                       PartyFoul::IssueRenderers::Rails
                     else
                       PartyFoul::IssueRenderers::Rack
                     end

    self.rendered_issue = renderer_klass.new(exception, env)
  end

  # Begins to process the exception for GitHub Issues. Makes an attempt
  # to find the issue. If found will update the issue. If not found will create a new issue.
  def run
    if issue = find_issue
      update_issue(issue)
    else
      create_issue
    end
  end

  # Hits the GitHub API to find the matching issue using the fingerprint.
  def find_issue
    find_first_issue('open') || find_first_issue('closed')
  end

  # Will create a new issue and a comment with the proper details. All issues are labeled as 'bug'.
  def create_issue
    self.sha = PartyFoul.github.references(PartyFoul.repo_path, "heads/#{PartyFoul.branch}").object.sha
    issue = PartyFoul.github.create_issue(PartyFoul.repo_path, rendered_issue.title, rendered_issue.body, labels: ['bug'] + rendered_issue.labels)
    PartyFoul.github.add_comment(PartyFoul.repo_path, issue[:number], rendered_issue.comment)
  end

  # Updates the given issue. If the issue is labeled as 'wontfix' nothing is done. If the issue is closed the issue is reopened and labeled as 'regression'.
  #
  # @param [Sawyer::Resource]
  def update_issue(issue)
    label_names = issue.key?(:labels) ? issue[:labels].map {|label| label[:name] } : []

    unless label_names.include?('wontfix')
      body = rendered_issue.update_body(issue[:body])
      params = {state: 'open'}

      if issue[:state] == 'closed'
        params[:labels] = (['bug', 'regression'] + label_names).uniq
      end

      self.sha = PartyFoul.github.references(PartyFoul.repo_path, "heads/#{PartyFoul.branch}").object.sha
      PartyFoul.github.update_issue(PartyFoul.repo_path, issue[:number], issue.title, body, params)

      unless comment_limit_met?(issue[:body])
        PartyFoul.github.add_comment(PartyFoul.repo_path, issue[:number], rendered_issue.comment)
      end
    end
  end

  private

  def self.clean_env(env)
    env.select do |key, value|
      begin
        Marshal.dump(value)
      rescue TypeError
        true
      rescue
        false
      end
    end
  end

  def fingerprint
    rendered_issue.fingerprint
  end

  def sha=(sha)
    rendered_issue.sha = sha
  end

  def occurrence_count(body)
    result = body.match(/<th>Count<\/th><td>(\d+)<\/td>/)
    result.nil? ? 0 : result[1].to_i
  end

  def comment_limit_met?(body)
    !!PartyFoul.comment_limit && PartyFoul.comment_limit <= occurrence_count(body)
  end

  def find_first_issue(state)
    PartyFoul.github.search_issues("#{fingerprint} repo:#{PartyFoul.repo_path} state:#{state}").items.first
  end
end
