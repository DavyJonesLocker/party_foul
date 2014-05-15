require 'rake'

module Rake
  class Application
    alias_method :orig_display_error_message, :display_error_message
    def display_error_message(ex)
      PartyFoul::RacklessExceptionHandler.handle(ex, {class: @rakefile, method: @name, params: ARGV.join(' ')})
      orig_display_error_message(ex)
    end
  end
end
