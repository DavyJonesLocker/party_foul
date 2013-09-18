require 'test_helper'
require 'rails/generators/test_case'
require 'generators/party_foul/install_generator'

class PartyFoul::GeneratorTest < Rails::Generators::TestCase
  destination File.expand_path('../tmp', __FILE__)
  tests PartyFoul::InstallGenerator

  test 'it copies the initializer' do
    owner = 'test_owner'
    repo  = 'test_repo'
    octokit = mock('Octokit')
    octokit.expects(:create_authorization).with(scopes: ['repo'], note: 'PartyFoul test_owner/test_repo', note_url: 'http://example.com/test_owner/test_repo').returns(sawyer_resource({token: 'test_token'}))
    Octokit.stubs(:new).with(:login => 'test_login', :password => 'test_password', :api_endpoint => 'http://api.example.com').returns(octokit)
    $stdin.stubs(:gets).returns('test_login').then.returns('test_password').then.returns(owner).then.returns(repo).then.returns('http://api.example.com').then.returns('http://example.com').then.returns('')
    run_generator

    assert_file 'config/initializers/party_foul.rb' do |initializer|
      assert_match(/config\.api_endpoint\s+=\s'http:\/\/api\.example\.com'/, initializer)
      assert_match(/config\.web_url\s+=\s'http:\/\/example\.com'/, initializer)
      assert_match(/config\.owner\s+=\s'test_owner'/, initializer)
      assert_match(/config\.repo\s+=\s'test_repo'/, initializer)
      assert_match(/config\.oauth_token\s+=\s'test_token'/, initializer)
    end
  end
end
