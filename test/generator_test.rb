require 'test_helper'
require 'rails/generators/test_case'
require 'generators/party_foul/install_generator'

class PartyFoul::GeneratorTest < Rails::Generators::TestCase
  destination File.expand_path('../tmp', __FILE__)
  tests PartyFoul::InstallGenerator
  test 'it copies the initializer' do
    $stdin.stubs(:gets).returns('')
    run_generator
    assert_file 'config/initializers/party_foul.rb'
  end
end
