require 'test_helper'
require 'rails/generators/test_case'
require 'generators/party_foul/install_generator'

class PartyFoul::GeneratorTest < Rails::Generators::TestCase
  destination File.expand_path('../tmp', __FILE__)
  tests PartyFoul::InstallGenerator
  test 'it copies the initializer' do
    owner = 'test_owner'
    repo  = 'test_repo'
    oauth = mock('Oauth')
    oauth.stubs(:create)
    oauth.expects(:create).with(scopes: ['repo'], note: 'PartyFoul test_owner/test_repo', note_url: 'http://example.com/test_owner/test_repo').returns(Hashie::Mash.new(token: 'test_token'))
    github = mock('Github')
    github.stubs(:oauth).returns(oauth)
    Github.stubs(:new).with(:login => 'test_login', :password => 'test_password', :endpoint => 'http://api.example.com').returns(github)
    $stdin.stubs(:gets).returns('test_login').then.returns('test_password').then.returns(owner).then.returns(repo).then.returns('http://api.example.com').then.returns('http://example.com').then.returns('')
    run_generator

    assert_file 'config/initializers/party_foul.rb' do |initializer|
      assert_match(/config\.endpoint\s+=\s'http:\/\/api\.example\.com'/, initializer)
      assert_match(/config\.web_url\s+=\s'http:\/\/example\.com'/, initializer)
      assert_match(/config\.owner\s+=\s'test_owner'/, initializer)
      assert_match(/config\.repo\s+=\s'test_repo'/, initializer)
      assert_match(/config\.oauth_token\s+=\s'test_token'/, initializer)
    end
  end
end
