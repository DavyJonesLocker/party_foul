class PartyFoul::Processors::Sync
  def self.handle(exception, env)
    PartyFoul::ExceptionHandler.new(exception, env).run
  end
end
