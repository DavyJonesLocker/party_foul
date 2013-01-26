require 'test_helper'

describe 'Party Foul Middleware' do
  include Rack::Test::Methods

  after do
    clean_up_party
  end

  def error_to_raise
    Exception
  end

  def app
    _self = self
    Rack::Builder.new {
      map '/' do
        use PartyFoul::Middleware
        run lambda { |env| raise _self.error_to_raise }
      end
    }
  end

  context 'handling an exception' do
    it 'does not handle exception' do
      PartyFoul::ExceptionHandler.stubs(:handle)
      PartyFoul::ExceptionHandler.expects(:handle)
      lambda {
        get '/'
      }.must_raise(Exception)
    end
  end

  context 'filtering based upon exception' do
    before do
      PartyFoul.ignored_exceptions = ['StandardError']
      self.stubs(:error_to_raise).returns(StandardError)
    end

    it 'does not handle exception' do
      PartyFoul::ExceptionHandler.stubs(:handle)
      PartyFoul::ExceptionHandler.expects(:handle).never
      lambda {
        get '/'
      }.must_raise(StandardError)
    end
  end
end
