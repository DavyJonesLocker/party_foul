require 'rails/generators'
require 'io/console'
require 'net/http'

module PartyFoul
  class SetupGenerator < Rails::Generators::Base

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
      name = ask 'Repository name:'
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
        token = JSON.parse(response.body)['token']

        File.open('config/initializers.party_foul.rb', 'w') do |f|
          f.puts <<-CONTENTS
client_id:     #{client_id}
client_secret: #{client_secret}
access_token:  #{token}
repo_owner:    #{owner}
repo_name:     #{name}
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
