require 'test_helper'
require 'rails/generators/test_case'
require 'generators/party_foul/install_generator'

class PartyFoul::GeneratorTest < Rails::Generators::TestCase
  destination File.expand_path('../tmp', __FILE__)
  tests PartyFoul::InstallGenerator
  test 'it copies the initializer' do
    oauth = mock('Oauth')
    oauth.stubs(:create)
    oauth.expects(:create).with('scopes' => ['repo'])
    github = mock('Github')
    github.stubs(:oauth).returns(oauth)
    github.stubs(:oauth_token).returns('test_token')
    Github.stubs(:new).with(:login => 'test_login', :password => 'test_password', :endpoint => 'test_endpoint').returns(github)
    $stdin.stubs(:gets).returns('test_login').then.returns('test_password').then.returns('').then.returns('test_repo').then.returns("test_endpoint").then.returns('')
    run_generator

    assert_file 'config/initializers/party_foul.rb' do |initializer|
      assert_match(/config.endpoint\s+=\s'test_endpoint'/, initializer)
      assert_match(/config.owner\s+=\s'test_login'/, initializer)
      assert_match(/config.repo\s+=\s'test_repo'/, initializer)
      assert_match(/config.oauth_token\s+=\s'test_token'/, initializer)
    end
  end
end
