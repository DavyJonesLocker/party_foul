# PartyFoul #

[![Build Status](https://secure.travis-ci.org/DockYard/party_foul.svg?branch=master)](http://travis-ci.org/DockYard/party_foul)
[![Dependency Status](https://gemnasium.com/dockyard/party_foul.svg?travis)](https://gemnasium.com/dockyard/party_foul)
[![Code Climate](https://codeclimate.com/github/dockyard/party_foul.svg)](https://codeclimate.com/github/dockyard/party_foul)

Rails exceptions automatically opened as issues on GitHub

## Looking for help? ##

If it is a bug [please open an issue on
GitHub](https://github.com/dockyard/party_foul/issues).

## About ##

`PartyFoul` captures exceptions in your application and does the
following:

1. Attempt to find a matching issue in your GitHub repo
2. If no matching issue is found, a new issue is created with a
   unique title, session information, and stack trace. The issue is
tagged as a `bug`. A new comment is added with relevant data on the
application state.
3. If an open issue is found, the occurrence count and time stamp is
   updated. A new comment is added with relevant data on the
application state.
4. If a closed issue is found, the occurrence count and time stamp is
   updated. The issue is reopened and a `regression` tag is
added. A new comment is added with relevant data on the
application state.
5. If the issue is marked as `wontfix` the issue is not updated nor is
   a new issue created. No comments are added.

## Installation ##

**Note** We highly recommend that you create a new GitHub account that is
a collaborator on your repository. Use this new account's credentials
for the installation below. If you use your own account you will
not receive emails when issues are created, updated, reopened, etc...
because all of the work is done as your account.

In your Gemfile add the following:

```ruby
gem 'party_foul'
```

### Rails ###
If you are using Rails you can run the install generator.

```
rails g party_foul:install
```

This prompts you for the GitHub credentials of the account that is
opening the issues. The OAuth token for that account is stored
in `config/initializers/party_foul.rb`. You may want to remove the token
string and store in an environment variable. It is best not to store the
token in version control.

Add as the very last middleware in your production `Rack` stack in `config/environments/production.rb`

```ruby
config.middleware.use('PartyFoul::Middleware')
```
### Other ###

You need to initialize `PartyFoul`, use the following:

```ruby
PartyFoul.configure do |config|
  # The collection of exceptions PartyFoul should not be allowed to handle
  # The constants here *must* be represented as strings
  config.blacklisted_exceptions = ['ActiveRecord::RecordNotFound', 'ActionController::RoutingError']

  # The OAuth token for the account that is opening the issues on GitHub
  config.oauth_token            = 'abcdefgh1234567890'

  # The API endpoint for GitHub. Unless you are hosting a private
  # instance of Enterprise GitHub you do not need to include this
  config.api_endpoint           = 'https://api.github.com'

  # The Web URL for GitHub. Unless you are hosting a private
  # instance of Enterprise GitHub you do not need to include this
  config.web_url                = 'https://github.com'

  # The organization or user that owns the target repository
  config.owner                  = 'owner_name'

  # The repository for this application
  config.repo                   = 'repo_name'

  # The branch for your deployed code
  # config.branch               = 'master'

  # Additional labels to add to issues created
  # config.additional_labels    = ['production']
  # or
  # config.additional_labels    = Proc.new do |exception, env|
  #   []
  # end

  # Limit the number of comments per issue
  # config.comment_limit        = 10

  # Setting your title prefix can help with
  # distinguising the issue between environments
  # config.title_prefix         = Rails.env
end
```

You can
[create an OAuth token](https://help.github.com/articles/creating-an-access-token-for-command-line-use/)
or generate an OAuth token via the
[OAuth Authorizations API](http://developer.github.com/v3/oauth/#oauth-authorizations-api) with cURL:

```bash
curl -u <github_login> -i -d "{ \"scopes\": [\"repo\"], \"note\":[\"Test\"] }" \
https://api.github.com/authorizations
```

## Customization ##

### Labels ###

You can specify an additional array of labels that will be applied to the issues PartyFoul creates.

```ruby
PartyFoul.configure do |config|
  config.additional_labels = ['front-end']
end
```

You can also provide a Proc that is passed the exception and the environment.

```ruby
PartyFoul.configure do |config|
  config.additional_labels = Proc.new do |exception, env|
    labels = if env["HTTP_HOST"] =~ /beta\./
      ['beta']
    else
      ['production']
    end
    if exception.message =~ /PG::Error/
      labels << 'database'
    end
    labels
  end
end
```

### Background Processing ###

You can specify the adapter with which the exceptions should be
handled. By default, PartyFoul includes the
[`PartyFoul::Processors::Sync`](https://github.com/dockyard/party_foul/tree/master/lib/party_foul/processors/sync.rb)
which handles the exception synchronously. To use your own adapter,
include the following in your `PartyFoul.configure` block:

```ruby
PartyFoul.configure do |config|
  config.processor = PartyFoul::Processors::MyBackgroundProcessor
end

class PartyFoul::Processors::MyBackgroundProcessor
  def self.handle(exception, env)
    # Enqueue the exception, then in your worker, call
    # PartyFoul::ExceptionHandler.new(exception, env).run
  end
end

```

`PartyFoul` comes with the following background processing adapters:

* [PartyFoul::Processors::Sidekiq](https://github.com/dockyard/party_foul/blob/master/lib/party_foul/processors/sidekiq.rb)
* [PartyFoul::Processors::Resque](https://github.com/dockyard/party_foul/blob/master/lib/party_foul/processors/resque.rb)
* [PartyFoul::Processors::DelayedJob](https://github.com/dockyard/party_foul/blob/master/lib/party_foul/processors/delayed_job.rb)

These adapters are not loaded by default. You must explicitly require if
you want to use:

```ruby
require 'party_foul/processors/sidekiq'

PartyFoul.configure do |config|
  config.processor = PartyFoul::Processors::Sidekiq
end
```

### Limiting Comments

You can specify a limit on the number of comments added to each issue. The main issue will still be updated
with a count and time for each occurrence, regardless of the limit.

```ruby
PartyFoul.configure do |config|
  config.comment_limit = 10
end
```

## Tracking errors outside of an HTTP request

You may want to track errors outside of a regular HTTP stack. In that
case you will need to make sure of the
`PartyFoul::RacklessExceptionHandler`.

The code that you want to handle should be wrapped like so:

```ruby
begin
  ... # some code that might raise an error
rescue => error
  PartyFoul::RacklessExceptionHandler.handle(error, class: class_name, method: method_name, params: message)
  raise error
end
```

### Tracking errors in a Sidekiq worker
In order to use PartyFoul for exception handling with Sidekiq you will need to create an initializer with some middleware configuration. The following example is based on using [Sidekiq with another exception notifier server](https://github.com/bugsnag/bugsnag-ruby/blob/master/lib/bugsnag/sidekiq.rb).

File: config/initializers/partyfoul_sidekiq.rb

```ruby
module PartyFoul
  class Sidekiq
    def call(worker, msg, queue)
      begin
        yield
      rescue => error
        PartyFoul::RacklessExceptionHandler.handle(error, {class: worker.class.name, method: queue, params: msg})
        raise error
      end
    end
  end
end

::Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.add ::PartyFoul::Sidekiq
  end
end
```

This will pass the worker class name and queue as well as all worker-related parameters off to PartyFoul before passing on the exception.

## Authors ##

* [Brian Cardarella](http://twitter.com/bcardarella)
* [Dan McClain](http://twitter.com/_danmcclain)

[We are very thankful for the many contributors](https://github.com/dockyard/party_foul/graphs/contributors)

## Versioning ##

This gem follows [Semantic Versioning](http://semver.org)

## Want to help? ##

Please do! We are always looking to improve this gem. Please see our
[Contribution Guidelines](https://github.com/dockyard/party_foul/blob/master/CONTRIBUTING.md)
on how to properly submit issues and pull requests.

## Legal ##

[DockYard](http://dockyard.com), LLC &copy; 2013

[@dockyard](http://twitter.com/dockyard)

[Licensed under the MIT license](http://www.opensource.org/licenses/mit-license.php)
