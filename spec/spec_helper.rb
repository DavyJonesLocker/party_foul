require 'rubygems'
begin
  require 'debugger'
rescue LoadError
end
begin
  require 'ruby-debug'
rescue LoadError
end
require 'bundler/setup'

ENV['RAILS_ENV'] = 'test'
require File.expand_path('../dummy/config/environment.rb',  __FILE__)
require 'capybara/rspec'
require 'rspec/rails'
require 'factory_girl_rails'

ENGINE_RAILS_ROOT=File.join(File.dirname(__FILE__), '../')

Dir[File.join(ENGINE_RAILS_ROOT, 'spec/support/**/*.rb')].each { |f| require f }
Dir[File.join(ENGINE_RAILS_ROOT, 'spec/config/**/*.rb')].each { |f| require f }

RSpec.configure do |config|
  config.mock_with :mocha
  config.use_transactional_fixtures = true
  config.include Factory::Syntax::Methods

  config.before(:each, :type => :request) do
    Dir[File.join(ENGINE_RAILS_ROOT, 'spec/requests/step_helpers/**/*.rb')].each { |f| require f }
  end
end
