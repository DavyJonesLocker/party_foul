module PartyFoul
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      @app.call(env)
    rescue Exception => e
      PartyFoul::ExceptionHandler.handle(e, env)
      raise e
    end
  end
end
