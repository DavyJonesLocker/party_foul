require 'rails/generators'
require 'io/console'
require 'debugger'
require 'net/http'

module PartyFoul
  class SetupGenerator < Rails::Generators::Base

    def create_configuration_file
      puts 'A Github Application is required'

      print 'Github App Client ID: '
      client_id = gets.strip
      print 'Github App Client Secret: '
      client_secret = gets.strip
      print 'Github username: '
      username = gets.strip
      print 'Github password: '
      password = STDIN.noecho(&:gets).strip
      puts ''

      print 'Repository owner: '
      owner = gets.strip
      print 'Repository name: '
      name = gets.strip
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

        File.open('config/party_foul.yml', 'w') do |f|
          f.puts <<-CONTENTS
client_id:     #{client_id}
client_secret: #{client_secret}
access_token:  #{token}
repo_owner:    #{owner}
repo_name:     #{name}
CONTENTS
        end
      end

      puts 'Done'
    end

    private

    def self.installation_message
      'Generates the configuration file'
    end

    desc installation_message
  end
end
