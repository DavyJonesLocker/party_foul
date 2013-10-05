require 'test_helper'

describe 'Rack Issue Renderer' do
  describe '#params' do
    before do
      @issue_renderer = PartyFoul::IssueRenderers::Rack.new(nil, ::Rack::MockRequest.env_for("/?status=ok"))
    end

    it 'returns the value of the query param' do
      @issue_renderer.params['status'].must_equal 'ok'
    end
  end
  
  describe '#raw_title' do
    before do
      @exception = Exception.new('message')
    end

    it 'constructs the title with the class and instance method' do
      @issue_renderer = PartyFoul::IssueRenderers::Rack.new(@exception, {})
      @issue_renderer.send(:raw_title).must_equal %{(Exception) "message"}
    end
  end
  
  describe '#request' do
    it 'builds a rack request' do
      issue_renderer = PartyFoul::IssueRenderers::Rack.new(nil, {})
      assert issue_renderer.request.is_a?(::Rack::Request)
    end
  end  
  
  describe '#ip_address' do
    # we are delegating to rack, see
    # https://github.com/rack/rack/blob/master/test/spec_request.rb    
    
    it 'returns the IP address when REMOTE_ADDR is set' do
      issue_renderer = PartyFoul::IssueRenderers::Rack.new(nil, { 'REMOTE_ADDR' => '1.2.3.4' })
      issue_renderer.ip_address.must_equal '1.2.3.4'
    end
    
    it 'return the IP address when HTTP_X_FORWARDED_FOR is set' do
      issue_renderer = PartyFoul::IssueRenderers::Rack.new(nil, { 'HTTP_X_FORWARDED_FOR' => '10.0.0.1, 10.0.0.1, 3.4.5.6' })
      issue_renderer.ip_address.must_equal '3.4.5.6'
    end
  end
  
  describe '#url' do
    it 'returns the method and uri' do
      issue_renderer = PartyFoul::IssueRenderers::Rack.new(nil, { 'REQUEST_METHOD' => 'GET', 'REQUEST_URI' => '/something' })
      issue_renderer.url.must_equal '[GET] /something'
    end    
  end  
  
  describe '#session' do
    it 'returns the session' do
      issue_renderer = PartyFoul::IssueRenderers::Rack.new(nil, { 'rack.session' => 'abc:123' })
      issue_renderer.session.must_equal 'abc:123'
    end    
  end
  
  describe '#http_headers' do
    it 'returns http headers' do
      issue_renderer = PartyFoul::IssueRenderers::Rack.new(nil, 
        { 
          'HTTP_VERSION' => 'version',
          'HTTP_USER_AGENT' => 'user agent',
          'HTTP_ACCEPT_ENCODING' => 'accept encoding',
          'HTTP_ACCEPT' => 'accept' 
        })
        
      issue_renderer.http_headers[:Version].must_equal 'version'
      issue_renderer.http_headers['User Agent'].must_equal 'user agent'
      issue_renderer.http_headers['Accept Encoding'].must_equal 'accept encoding'
      issue_renderer.http_headers[:Accept].must_equal 'accept'
    end    
  end
      
end
