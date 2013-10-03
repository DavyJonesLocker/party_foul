require 'test_helper'

describe 'Rack Issue Renderer' do
  describe '#params' do
    before do
      @rendered_issue = PartyFoul::IssueRenderers::Rack.new(nil, {'QUERY_STRING' => { 'status' => 'ok' } })
    end

    it 'returns ok' do
      @rendered_issue.params['status'].must_equal 'ok'
    end
  end

  describe '#raw_title' do
    before do
      @exception = Exception.new('message')
    end

    it 'constructs the title with the class and instance method' do
      @rendered_issue = PartyFoul::IssueRenderers::Rack.new(@exception, {})
      @rendered_issue.send(:raw_title).must_equal %{(Exception) "message"}
    end
  end
  
  describe '#request' do
    it 'builds a rack request' do
      issue = PartyFoul::IssueRenderers::Rack.new(nil, {})
      assert issue.request.is_a?(::Rack::Request)
    end
  end  
  
  describe '#ip_address' do
    # we are delegating to rack, see
    # https://github.com/rack/rack/blob/master/test/spec_request.rb    
    
    it 'returns the IP address when REMOTE_ADDR is set' do
      issue = PartyFoul::IssueRenderers::Rack.new(nil, {'REMOTE_ADDR' => '1.2.3.4' })
      issue.ip_address.must_equal '1.2.3.4'
    end
    
    it 'return the IP address when HTTP_X_FORWARDED_FOR is set' do
      issue = PartyFoul::IssueRenderers::Rack.new(nil, {'HTTP_X_FORWARDED_FOR' => '10.0.0.1, 10.0.0.1, 3.4.5.6' })
      issue.ip_address.must_equal '3.4.5.6'
    end
  end
  
  describe '#url' do
    it 'returns the method and uri' do
      issue = PartyFoul::IssueRenderers::Rack.new(nil, {'REQUEST_METHOD' => 'GET', 'REQUEST_URI' => '/something' })
      issue.url.must_equal '[GET] /something'
    end    
  end  
  
end
