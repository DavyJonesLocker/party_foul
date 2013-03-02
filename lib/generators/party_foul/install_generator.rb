require 'rails/generators'
require 'io/console'
require 'net/http'

module PartyFoul
  class InstallGenerator < Rails::Generators::Base
    source_root File.expand_path('../templates', __FILE__)

    def create_initializer_file
      login     = ask 'GitHub login:'
      password  = ask 'GitHub password:'
      @owner    = ask_with_default "\nRepository owner:", login
      @repo     = ask 'Repository name:'
      @endpoint = ask_with_default 'Api Endpoint:', 'https://api.github.com'
      @web_url  = ask_with_default 'Web URL:', 'https://github.com'

      begin
        github       = Github.new :login => login, :password => password, :endpoint => @endpoint
        @oauth_token = github.oauth.create(scopes: ['repo'], note: "PartyFoul #{@owner}/#{@repo}", note_url: "#{@web_url}/#{@owner}/#{@repo}").token
        template 'party_foul.rb', 'config/initializers/party_foul.rb'
      rescue Github::Error::Unauthorized
        say 'There was an error retrieving your GitHub OAuth token'
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
