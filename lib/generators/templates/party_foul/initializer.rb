PartyFoul.configure do |config|
  # the collection of exceptions to be ignored by PartyFoul
  # The constants here *must* be represented as strings
  config.ignored_exceptions = ['ActiveRecord::RecordNotFound']

  # The OAuth token for the account that will be opening the issues on Github
  config.oauth_token        = '<%= config[:oauth_token] %>'

  # The API endpoint for Github. Unless you are hosting a private
  # instance of Enterprise Github you do not need to include this
  config.endpoint           = '<%= config[:github_endpoint] %>'

  # The organization or user that owns the target repository
  config.owner              = '<%= config[:owner] %>'

  # The repository for this application
  config.repo               = '<%= config[:repo] %>'
end
