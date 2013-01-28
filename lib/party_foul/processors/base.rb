class PartyFoul::Processors::Base
  # Passes the exception and rack env data to the ExceptionHandler and
  # runs everything synchronously. This base class method must be
  # overriden by any inheriting class.
  #
  # @param [Exception, Hash]
  # @return [NotImplementedError]
  def self.handle(exception, env)
    raise NotImplementedError
  end
end
