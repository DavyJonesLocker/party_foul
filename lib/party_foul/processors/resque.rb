require 'party_foul/processors/base'

class PartyFoul::Processors::Resque < PartyFoul::Processors::Base
  @queue = :party_foul

  # Passes the exception and rack env data to Resque to be processed later
  #
  # @param [Exception, Hash]
  def self.handle(exception, env)
    Resque.enqueue(PartyFoul::Processors::Resque, Marshal.dump(exception), Marshal.dump(env))
  end

  def self.perform(exception, env)
    PartyFoul::ExceptionHandler.new(Marshal.load(exception), Marshal.load(env)).run
  end
end
