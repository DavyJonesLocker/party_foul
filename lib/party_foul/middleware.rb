module PartyFoul
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      @app.call(env)
    rescue Exception => captured_exception
      PartyFoul::ExceptionHandler.handle(captured_exception, env)
      raise captured_exception
    end
  end
end
