require 'rails/generators'
require 'io/console'
require 'net/http'

module PartyFoul
  class InstallGenerator < Rails::Generators::Base
    source_root File.expand_path('../templates', __FILE__)

    def create_initializer_file
      puts <<-MESSAGE
A Github Application is required.
If you do not already have one setup for your
repo then you need to do so now.
MESSAGE

      client_id     = ask 'Github App Client ID:'
      client_secret = ask 'Github App Client Secret:'
      username      = ask 'Github username:'
      password      = STDIN.noecho do
        ask 'Github password:'
      end

      say ''

      @owner    = ask 'Repository owner:'
      @repo     = ask 'Repository name:'
      @endpoint = ask_with_default 'Endpoint:', 'http://api.github.com'
      auth_uri  = URI('https://api.github.com/authorizations')

      response = nil

      Net::HTTP.start(auth_uri.host, auth_uri.port, :use_ssl => auth_uri.scheme == 'https') do |http|
        request      = Net::HTTP::Post.new auth_uri.request_uri
        body         = { :scopes => ['repo'], :client_id => client_id, :client_secret => client_secret }
        request.body = body.to_json
        request.basic_auth username, password
        response     = http.request request
      end

      if response.code == '201'
        @oauth_token = JSON.parse(response.body)['token']
        template 'party_foul.rb', 'config/initializers/party_foul.rb'
      else
        say 'There was an error retrieving your Github OAuth token'
      end
    end

    private

    def self.installation_message
      'Generates the initializer'
    end

    desc installation_message

    def ask_with_default(prompt, default)
      value = ask("#{prompt} [#{default}]")
      value.blank? ? default : value
    end
  end
end
