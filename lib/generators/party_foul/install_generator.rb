require 'rails/generators'
require 'io/console'
require 'net/http'

module PartyFoul
  class InstallGenerator < Rails::Generators::Base

    def create_initializer_file
      puts 'A Github Application is required'

      client_id = ask 'Github App Client ID:'
      client_secret = ask 'Github App Client Secret:'
      username = ask 'Github username:'
      password = STDIN.noecho do
        ask 'Github password:'
      end
      say ''

      owner = ask 'Repository owner:'
      repo  = ask 'Repository name:'
      auth_uri = URI("https://api.github.com/authorizations")

      response = nil
      Net::HTTP.start(auth_uri.host, auth_uri.port, :use_ssl => auth_uri.scheme == 'https') do |http|
        request = Net::HTTP::Post.new auth_uri.request_uri
        body = { :scopes => ['repo'], :client_id => client_id, :client_secret => client_secret }
        request.body = body.to_json

        request.basic_auth username, password

        response = http.request request
      end

      if response.code == '201'
        oauth_token = JSON.parse(response.body)['token']

        File.open('config/initializers.party_foul.rb', 'w') do |f|
          f.puts <<-CONTENTS
PartyFoul.configure do |config|
  # the collection of exceptions to be ignored by PartyFoul
  config.ignored_exceptions = [ActiveRecord::RecordNotFound]

  # The OAuth token for the account that will be opening the issues on Github
  config.oauth_token        = '#{oauth_token}'

  # The API endpoint for Github. Unless you are hosting a private
  # instance of Enterprise Github you do not need to include this
  # config.endpoint         = 'https://api.github.com'

  # The organization or user that owns the target repository
  config.owner              = '#{owner}'

  # The repository for this application
  config.repo               = '#{repo}'
end
CONTENTS
        end
      else
        say 'There was an error retrieving your Github OAuth token'
      end

      say 'Done'
    end

    private

    def self.installation_message
      'Generates the configuration file'
    end

    desc installation_message
  end
end
