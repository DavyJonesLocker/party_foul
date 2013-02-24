source "http://rubygems.org"

gemspec
unless ENV['CI'] || RUBY_PLATFORM =~ /java/ || RUBY_VERSION >= '2.0.0'
  gem 'debugger'
end
