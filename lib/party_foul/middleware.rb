module PartyFoul
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      @app.call(env)
    rescue Exception => captured_exception
      if allow_handling?(captured_exception)
        PartyFoul::ExceptionHandler.handle(captured_exception, env)
      end
      raise captured_exception
    end

    private

    def allow_handling?(captured_exception)
      !PartyFoul.ignored_exceptions.find do |ignored_exception|
        ignored_exception_class = Object.const_defined?(ignored_exception) ? Object.const_get(ignored_exception) : Object.const_missing(ignored_exception)
        ignored_exception_class === captured_exception
      end
    end
  end
end
