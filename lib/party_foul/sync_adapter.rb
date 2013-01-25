class PartyFoul::SyncAdapter
  def self.handle(exception, env)
    PartyFoul::ExceptionHandler.new(exception, env).run
  end
end
