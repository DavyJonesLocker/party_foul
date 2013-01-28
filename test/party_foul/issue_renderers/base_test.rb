require 'test_helper'
require 'active_support/core_ext/object/blank'
require 'action_dispatch/http/parameter_filter'

describe 'Party Foul Issue Renderer Base' do
  before do
    Time.stubs(:now).returns(Time.new(1970, 1, 1, 0, 0, 0, '-05:00'))
  end

  after do
    clean_up_party
  end

  describe '#body' do
    describe 'updating issue body' do
      before do
        @rendered_issue = PartyFoul::IssueRenderers::Base.new(nil, nil)
        @rendered_issue.stubs(:exception).returns('Test Exception')
        @rendered_issue.stubs(:fingerprint).returns('abcdefg1234567890')
        @rendered_issue.stubs(:stack_trace)
      end

      it 'updates count and timestamp' do
        body = <<-BODY
<table>
<tr><th>Exception</th><td>Test Exception</td></tr>
<tr><th>Count</th><td>1</td></tr>
<tr><th>Last Occurance</th><td>January 01, 1970 00:00:00 -0500</td></tr>
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
<tr><th>Last Occurance</th><td>October 25, 1985 01:22:00 -0500</td></tr>
</table>

## Stack Trace
<pre></pre>
Fingerprint: `abcdefg1234567890`
    BODY

        @rendered_issue.update_body(body).must_equal expected_body
      end
    end

    describe 'empty body' do
      before do
        @rendered_issue = PartyFoul::IssueRenderers::Base.new(nil, nil)
        @rendered_issue.stubs(:exception).returns('Test Exception')
        @rendered_issue.stubs(:fingerprint).returns('abcdefg1234567890')
        @rendered_issue.stubs(:stack_trace)
      end

      it 'resets body' do
        expected_body = <<-BODY
<table>
<tr><th>Exception</th><td>Test Exception</td></tr>
<tr><th>Count</th><td>1</td></tr>
<tr><th>Last Occurance</th><td>January 01, 1970 00:00:00 -0500</td></tr>
</table>

## Stack Trace
<pre></pre>
Fingerprint: `abcdefg1234567890`
    BODY
        @rendered_issue.update_body(nil).must_equal expected_body
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
        'rack.session' => { :id => 1 }
      }
      @rendered_issue = PartyFoul::IssueRenderers::Base.new(nil, env)
      @rendered_issue.stubs(:params).returns({})
    end

    it 'renders a new comment' do
      expected_comment = <<-COMMENT
<table>
<tr><th>Occurred at</th><td>January 01, 1970 00:00:00 -0500</td></tr>
<tr><th>Params</th><td><table></table></td></tr>
<tr><th>IP Address</th><td>127.0.0.1</td></tr>
<tr><th>Session</th><td><table><tr><th>id</th><td>1</td></tr></table></td></tr>
<tr><th>HTTP Headers</th><td><table><tr><th>Host</th><td>localhost:3000</td></tr><tr><th>User-Agent</th><td>test_user_agent</td></tr></table></td></tr>
</table>
COMMENT

      @rendered_issue.comment.must_equal expected_comment
    end
  end

  describe '#compile_template' do
    it 'it parses the tags and inserts proper data' do
      template = '<span>:data1</span><div>:data2</div>'
      @rendered_issue = PartyFoul::IssueRenderers::Base.new(nil, nil)
      @rendered_issue.stubs(:data1).returns('123')
      @rendered_issue.stubs(:data2).returns('abc')
      @rendered_issue.compile_template(template).must_equal '<span>123</span><div>abc</div>'
    end
  end

  describe '#http_headers' do
    before do
      PartyFoul.filtered_http_headers = ['Cookie']
      env = {
        'HTTP_USER_AGENT' => 'test_user_agent',
        'HTTP_COOKIE' => 'test_cookie',
      }
      @rendered_issue = PartyFoul::IssueRenderers::Base.new(nil, env)
    end

    it 'ignored Cookie' do
      @rendered_issue.http_headers.must_equal('User-Agent' => 'test_user_agent')
    end
  end

  describe '#fingerprint' do
    it 'SHA1s the title' do
      rendered_issue = PartyFoul::IssueRenderers::Base.new(nil, nil)
      rendered_issue.stubs(:title).returns('abcdefg1234567890')
      rendered_issue.fingerprint.must_equal Digest::SHA1.hexdigest(rendered_issue.title)
    end
  end
end
