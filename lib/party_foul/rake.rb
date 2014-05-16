module PartyFoul::RakeHandler
  def self.included(klass)
    klass.class_eval do
      alias_method :display_error_message_without_party_foul, :display_error_message
      alias_method :display_error_message, :display_error_message_with_party_foul
    end
  end

  def display_error_message_with_party_foul(exception)
    PartyFoul::RacklessExceptionHandler.handle(exception, {class: @rakefile, method: @name, params: ARGV.join(' ')})
    display_error_message_without_party_foul(exception)
  end
end

Rake.application.instance_eval do
  class << self
    include PartyFoul::RakeHandler
  end
end
