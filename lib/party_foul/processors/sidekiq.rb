require 'party_foul/processors/base'

class PartyFoul::Processors::Sidekiq < PartyFoul::Processors::Base
  include Sidekiq::Worker
  sidekiq_options queue: 'party_foul'

  # Passes the exception and rack env data to Sidekiq to be processed later
  #
  # @param [Exception, Hash]
  def self.handle(exception, env)
    perform_async(Marshal.dump(exception), Marshal.dump(env))
  end

  def perform(exception, env)
    PartyFoul::ExceptionHandler.new(Marshal.load(exception), Marshal.load(env)).run
  end
end
