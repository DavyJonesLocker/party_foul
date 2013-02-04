require 'party_foul/processors/base'

class PartyFoul::Processors::DelayedJob < PartyFoul::Processors::Base
  @queue = 'party_foul'

  # Passes the exception and rack env data to DelayedJob to be processed later
  #
  # @param [Exception, Hash]
  def self.handle(exception, env)
    new.delay(queue: @queue).perform(Marshal.dump(exception), Marshal.dump(env))
  end

  def perform(exception, env)
    PartyFoul::ExceptionHandler.new(Marshal.load(exception), Marshal.load(env)).run
  end
end
