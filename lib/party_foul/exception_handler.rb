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

  # Begins to process the exception for Github Issues. Makes an attempt
  # to find the issue. If found will update the issue. If not found will create a new issue.
  def run
    if issue = find_issue
      update_issue(issue)
    else
      create_issue
    end
  end

  # Hits the Github API to find the matching issue using the fingerprint.
  def find_issue
    unless issue = PartyFoul.github.search.issues(owner: PartyFoul.owner, repo: PartyFoul.repo, state: 'open', keyword: fingerprint).issues.first
      issue = PartyFoul.github.search.issues(owner: PartyFoul.owner, repo: PartyFoul.repo, state: 'closed', keyword: fingerprint).issues.first
    end

    issue
  end

  # Will create a new issue and a comment with the proper details. All issues are labeled as 'bug'.
  def create_issue
    self.sha = PartyFoul.github.git_data.references.get(PartyFoul.owner, PartyFoul.repo, "heads/#{PartyFoul.branch}").object.sha
    issue = PartyFoul.github.issues.create(PartyFoul.owner, PartyFoul.repo, title: rendered_issue.title, body: rendered_issue.body, labels: ['bug'] + rendered_issue.labels)
    PartyFoul.github.issues.comments.create(PartyFoul.owner, PartyFoul.repo, issue['number'], body: rendered_issue.comment)
  end

  # Updates the given issue. If the issue is labeled as 'wontfix' nothing is done. If the issue is closed the issue is reopened and labeled as 'regression'.
  #
  # @param [Hashie::Mash]
  def update_issue(issue)
    unless issue.key?('labels') && issue['labels'].include?('wontfix')
      params = {body: rendered_issue.update_body(issue['body']), state: 'open'}

      if issue['state'] == 'closed'
        params[:labels] = (['bug', 'regression'] + issue['labels']).uniq
      end

      self.sha = PartyFoul.github.git_data.references.get(PartyFoul.owner, PartyFoul.repo, "heads/#{PartyFoul.branch}").object.sha
      PartyFoul.github.issues.edit(PartyFoul.owner, PartyFoul.repo, issue['number'], params)
      PartyFoul.github.issues.comments.create(PartyFoul.owner, PartyFoul.repo, issue['number'], body: rendered_issue.comment)
    end
  end

  private

  def self.clean_env(env)
    env.select { |key, value| PartyFoul.whitelisted_rack_variables.include?(key) }
  end

  def fingerprint
    rendered_issue.fingerprint
  end

  def sha=(sha)
    rendered_issue.sha = sha
  end
end
