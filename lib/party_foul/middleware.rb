module PartyFoul
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      @app.call(env)
    rescue Exception => captured_exception
      unless PartyFoul.ignored_exceptions.find { |ignored_exception| ignored_exception === captured_exception }
        PartyFoul::ExceptionHandler.handle(captured_exception, env)
      end
      raise captured_exception
    end
  end
end
