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
        names = ignored_exception.split('::')
        names.shift if names.empty? || names.first.empty?

        constant = Object
        names.each do |name|
          constant = constant.const_defined?(name) ? constant.const_get(name) : constant.const_missing(name)
        end

        constant === captured_exception
      end
    end
  end
end
