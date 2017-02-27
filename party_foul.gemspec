# Maintain your gem's version:
require File.expand_path('../lib/party_foul/version', __FILE__)

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'party_foul'
  s.version     = PartyFoul::VERSION
  s.authors     = ['Brian Cardarella', 'Dan McClain']
  s.email       = ['bcardarella@gmail.com', 'rubygems@danmcclain.net']
  s.homepage    = 'https://github.com/dockyard/party_foul'
  s.summary     = 'Auto-submit Rails exceptions as new issues on GitHub'
  s.description = 'Auto-submit Rails exceptions as new issues on GitHub'
  s.license     = 'MIT'

  s.required_ruby_version = '>= 2.1.0'

  s.files = Dir['{app,config,db,lib}/**/*'] + ['Rakefile', 'README.md']
  s.test_files = Dir['test/**/*']

  s.add_dependency 'octokit', '~> 4.2'

  s.add_development_dependency 'actionpack', '~> 4.0'
  s.add_development_dependency 'activesupport', '~> 4.0'
  s.add_development_dependency 'railties', '~> 4.0'
  s.add_development_dependency 'minitest', '~> 5.8'
  s.add_development_dependency 'webmock'
  s.add_development_dependency 'rack-test'
  s.add_development_dependency 'mocha'
  s.add_development_dependency 'm'
end
