source "https://rubygems.org"

gemspec
unless ENV['CI'] || RUBY_PLATFORM =~ /java/
  if RUBY_VERSION >= '2.0.0'
    gem 'byebug'
  end
end
