require 'party_foul/processors/base'

class PartyFoul::Processors::Sync < PartyFoul::Processors::Base
  # Passes the exception and rack env data to the ExceptionHandler and
  # runs everything synchronously.
  #
  # @param [Exception, Hash]
  def self.handle(exception, env)
    PartyFoul::ExceptionHandler.new(exception, env).run
  end
end
