require 'rails/generators'
require 'io/console'
require 'net/http'

module PartyFoul
  class InstallGenerator < Rails::Generators::Base

    def create_initializer_file
      source_paths << File.expand_path('../../templates/party_foul', __FILE__)

      say 'A Github Application is required'

      github_endpoint = ask('Github API endpoint: [https://api.github.com]')
      github_endpoint = 'https://api.github.com' if github_endpoint.blank?

      client_id = ask 'Github App Client ID:'
      client_secret = ask 'Github App Client Secret:'
      username = ask 'Github username:'
      password = STDIN.noecho do
        ask 'Github password:'
      end
      say ''

      owner = ask "Repository owner: [#{username}]"
      owner = username if owner.blank?

      repo  = ask 'Repository name:'
      auth_uri = URI("#{github_endpoint}/authorizations")

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

        template 'initializer.rb', 'config/initializers/party_foul.rb',
          :oauth_token => oauth_token, :github_endpoint => github_endpoint, :owner => owner, :repo => repo
      else
        say 'There was an error retrieving your Github OAuth token'
      end
    end

    private

    def self.installation_message
      'Generates the configuration file'
    end

    desc installation_message
  end
end
