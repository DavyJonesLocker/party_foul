class PartyFoul::Processors::Sync
  # Passes the exception and rack env data to the ExceptionHandler and
  # runs everything synchronously.
  #
  # @param [Exception, Hash]
  def self.handle(exception, env)
    PartyFoul::ExceptionHandler.new(exception, env).run
  end
end
