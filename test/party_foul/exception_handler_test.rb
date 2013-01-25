require 'test_helper'
require 'active_support/core_ext/object/blank'
require 'action_dispatch/http/parameter_filter'

describe 'Party Foul Exception Handler' do
  before do
    Time.stubs(:now).returns(Time.at(0))
  end

  describe '#body' do
    describe 'updating issue body' do
      before do
        @handler = PartyFoul::ExceptionHandler.new(nil, nil)
        @handler.stubs(:exception).returns('Test Exception')
        @handler.stubs(:fingerprint).returns('abcdefg1234567890')
        @handler.stubs(:stack_trace)
      end

      it 'updates count and timestamp' do
        body = <<-BODY
<table>
<tr><th>Exception</th><td>Test Exception</td></tr>
<tr><th>Count</th><td>1</td></tr>
<tr><th>Last Occurance</th><td>#{Time.now}</td></tr>
</table>

## Stack Trace
<pre></pre>
Fingerprint: `abcdefg1234567890`
    BODY

        Time.stubs(:now).returns(Time.new(1985, 10, 25, 1, 22, 0, '-05:00'))

        expected_body = <<-BODY
<table>
<tr><th>Exception</th><td>Test Exception</td></tr>
<tr><th>Count</th><td>2</td></tr>
<tr><th>Last Occurance</th><td>#{Time.now}</td></tr>
</table>

## Stack Trace
<pre></pre>
Fingerprint: `abcdefg1234567890`
    BODY

        @handler.update_body(body).must_equal expected_body
      end
    end

    describe 'empty body' do
      before do
        @handler = PartyFoul::ExceptionHandler.new(nil, nil)
        @handler.stubs(:exception).returns('Test Exception')
        @handler.stubs(:fingerprint).returns('abcdefg1234567890')
        @handler.stubs(:stack_trace)
      end

      it 'resets body' do
        expected_body = <<-BODY
<table>
<tr><th>Exception</th><td>Test Exception</td></tr>
<tr><th>Count</th><td>1</td></tr>
<tr><th>Last Occurance</th><td>#{Time.now}</td></tr>
</table>

## Stack Trace
<pre></pre>
Fingerprint: `abcdefg1234567890`
    BODY
        @handler.update_body(nil).must_equal expected_body
      end
    end
  end

  describe '#params' do
    context 'with Rails' do
      before do
        @handler = PartyFoul::ExceptionHandler.new(nil, {'action_dispatch.parameter_filter' => ['password'], 'action_dispatch.request.path_parameters' => { 'status' => 'ok', 'password' => 'test' }, 'QUERY_STRING' => { 'status' => 'fail' } })
      end

      it 'returns ok' do
        @handler.params['status'].must_equal 'ok'
        @handler.params['password'].must_equal '[FILTERED]'
      end
    end

    context 'without Rails' do
      before do
        @handler = PartyFoul::ExceptionHandler.new(nil, {'QUERY_STRING' => { 'status' => 'ok' } })
      end

      it 'returns ok' do
        @handler.params['status'].must_equal 'ok'
      end
    end
  end

  describe '#issue_comment' do
    before do
      env = {
        'REQUEST_URI' => 'http://example.com/',
        'HTTP_USER_AGENT' => 'test_user_agent',
        'REMOTE_ADDR' => '127.0.0.1',
        'HTTP_HOST' => 'localhost:3000',
        'QUERY_STRING' => { :controller => 'landing', :action => 'index' }
      }
      @handler = PartyFoul::ExceptionHandler.new(nil, env)
    end

    it 'renders a new comment' do
      expected_comment = <<-COMMENT
<table>
<tr><th>Occurred at</th><td>#{Time.now}</td></tr>
<tr><th>Params</th><td>{:controller=>"landing", :action=>"index"}</td></tr>
<tr><th>IP Address</th><td>127.0.0.1</td></tr>
<tr><th>HTTP Headers</th><td><table><tr><th>Host</th><td>localhost:3000</td></tr><tr><th>User Agent</th><td>test_user_agent</td></tr></table></td></tr>
</table>
COMMENT

      @handler.comment_body.must_equal expected_comment
    end
  end

  describe '#compile_template' do
    it 'it parses the tags and inserts proper data' do
      template = '<span>:data1</span><div>:data2</div>'
      @handler = PartyFoul::ExceptionHandler.new(nil, nil)
      @handler.stubs(:data1).returns('123')
      @handler.stubs(:data2).returns('abc')
      @handler.compile_template(template).must_equal '<span>123</span><div>abc</div>'
    end
  end
end
