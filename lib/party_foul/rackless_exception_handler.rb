class PartyFoul::RacklessExceptionHandler < PartyFoul::ExceptionHandler
  # This handler will pass the exception and working environment from Rack off to a processor.
  # The default PartyFoul processor will work synchronously. Processor adapters can be written
  # to push this logic to a background job if desired.
  #
  # @param [Exception, Hash]
  def self.handle(exception, env)
    if allow_handling?(exception)
      self.new(exception, clean_env(env)).run
    end
  end

  # Uses the Rackless IssueRenderer for a rackless environment
  #
  # @param [Exception, Hash]
  def initialize(exception, env)
    self.rendered_issue = PartyFoul::IssueRenderers::Rackless.new(exception, env)
  end
end
