class PartyFoul::ExceptionHandler
  attr_accessor :rendered_issue

  def self.handle(exception, env)
    PartyFoul.processor.handle(exception, env)
  end

  def initialize(exception, env)
    renderer_klass = if defined?(Rails)
                       PartyFoul::RailsIssueRenderer
                     else
                       PartyFoul::RackIssueRenderer
                     end

    self.rendered_issue = renderer_klass.new(exception, env)
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

  def create_issue
    issue = PartyFoul.github.issues.create(PartyFoul.owner, PartyFoul.repo, title: rendered_issue.title, body: rendered_issue.body, labels: ['bug'])
    PartyFoul.github.issues.comments.create(PartyFoul.owner, PartyFoul.repo, issue['number'], body: rendered_issue.comment)
  end

  def update_issue(issue)
    unless issue.key?('labels') && issue['labels'].include?('wontfix')
      params = {body: rendered_issue.update_body(issue['body']), state: 'open'}

      if issue['state'] == 'closed'
        params[:labels] = ['bug', 'regression']
      end

      PartyFoul.github.issues.edit(PartyFoul.owner, PartyFoul.repo, issue['number'], params)
      PartyFoul.github.issues.comments.create(PartyFoul.owner, PartyFoul.repo, issue['number'], body: rendered_issue.comment)
    end
  end

  private

  def fingerprint
    rendered_issue.fingerprint
  end
end
