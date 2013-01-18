require 'active_support'

module PartyFoul
  extend ActiveSupport::Autoload

  autoload :Engine
  autoload :Middleware
  autoload :ExceptionHandler
end
