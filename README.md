# PartyFoul #

[![Build Status](https://secure.travis-ci.org/dockyard/party_foul.png?branch=master)](http://travis-ci.org/dockyard/party_foul)
[![Dependency Status](https://gemnasium.com/dockyard/party_foul.png?travis)](https://gemnasium.com/dockyard/party_foul)
[![Code Climate](https://codeclimate.com/badge.png)](https://codeclimate.com/github/dockyard/party_foul)

Rails exceptions automatically opened as issues on Github

## About ##

`PartyFoul` captures exceptions in your application and does the
following:

1. Attempt to find a matching issue in your Github repo
2. If no matching issue is found an new issue is created with a
   unique title, session information, and stack trace. The issue is
tagged as a `bug`. A new comment is added with relevant data on the
application state.
3. If an open issue is found the occurence count and time stamp is
   updated. A new comment is added with relevant data on the
application state.
4. If a closed issue is found the occurence count and time stamp is
   updated. The issue is reopened and a `regression` tag is
added. A new comment is added with relevant data on the
application state.
5. If the issue is marked as `wontfix` the issue is not updated nor is
   a new issue created. No comments are added.

## Installation ##

**Note** We highly recommend that you create a new Github account that is
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

This prompts you for the Github credentials of the account that is
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

  # The list of HTTP Headers that PartyFoul should be allowed to report
  config.blacklisted_headers    = ['Cookie']

  # The OAuth token for the account that is opening the issues on Github
  config.oauth_token            = 'abcdefgh1234567890'

  # The API endpoint for Github. Unless you are hosting a private
  # instance of Enterprise Github you do not need to include this
  config.endpoint               = 'https://api.github.com'

  # The Web URL for Github. Unless you are hosting a private
  # instance of Enterprise Github you do not need to include this
  config.web_url                = 'https://github.com'

  # The organization or user that owns the target repository
  config.owner                  = 'owner_name'

  # The repository for this application
  config.repo                   = 'repo_name'

  # The branch for your deployed code
  # config.branch               = 'master'
end
```

You can generate an OAuth token from via the
[OAuth Authorizations API](http://developer.github.com/v3/oauth/#oauth-authorizations-api)
with cURL:

```bash
curl -u <github_login> -i -d "{ \"scopes\": [\"repo\"] }" \
https://api.github.com/authorizations
```

Add as the very last middleware in your production `Rack` stack.

## Customization ##

### Background Processing ###

You can specify the adapter with which the exceptions should be
handled. By default, PartyFoul includes the
[`PartyFoul::SyncAdapter`](https://github.com/dockyard/party_foul/tree/master/lib/party_foul/sync_adapter.rb)
which handles the exception synchronously. To use your own adapter,
include the following in your `PartyFoul.configure` block:

```ruby
PartyFoul.configure do |config|
  config.adapter = PartyFoul::Processors::MyBackgroundProcessor
end

class PartyFoul::Processors::MyBackgroundProcessor
  def self.handle(exception, env)
    # Enqueue the exception, then in your worker, call
    # PartyFoul::ExceptionHandler.new(exception, env).run
  end
end

```

### Changing How Issues Are Reported ###

`PartyFoul` comes with default templates for what the body of issues and
comments are. If you want to override these templates you simply need to
add them as an option in your initializer:

```ruby
PartyFoul.configure do |config|
  config.issue_body   = ':issue_title'
  config.comment_body = ':occurred_at'
end
```

In this over-simplistic example the words that start with `:` in the
templates are evaluated with the value of the corresponding named
instance method on the instance of `PartyFoul::IssueRenderer`. If you
want to add additional values for replacement you should open that class
to add the methods. Depending upon the data point you may want o make
the change in one of the [different issue renderer adapters](https://github.com/dockyard/party_foul/tree/master/lib/party_foul/issue_renderers).

### Using PartyFoul with Sidekiq

In order to use PartyFoul for exception handling with Sidekiq you will need to create an initializer with some middleware configuration. The following example is based on using [Sidekiq with another exception notifiier server](https://github.com/bugsnag/bugsnag-ruby/blob/master/lib/bugsnag/sidekiq.rb).

File: config/initializers/partyfoul_sidekiq.rb

```ruby
module PartyFoul
  class Sidekiq
    def call(worker, msg, queue)
      begin
        yield
      rescue => ex
        PartyFoul::RacklessExceptionHandler.handle(ex, {class: worker.class.name, method: queue, params: msg})
        raise
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
