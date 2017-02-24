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
        body = <<-BODY.gsub(/\n/, '')
<table>
<tr><th>Exception</th><td>Test Exception</td></tr>
<tr><th>Last Occurrence</th><td>January 01, 1970 00:00:00 -0500</td></tr>
<tr><th>Count</th><td>1</td></tr>
</table>

## Stack Trace
<pre></pre>
Fingerprint: `abcdefg1234567890`
    BODY

        Time.stubs(:now).returns(Time.new(1985, 10, 25, 1, 22, 0, '-05:00'))

        expected_body = <<-BODY.gsub(/\n/, '')
<table>
<tr><th>Exception</th><td>Test Exception</td></tr>
<tr><th>Last Occurrence</th><td>October 25, 1985 01:22:00 -0500</td></tr>
<tr><th>Count</th><td>2</td></tr>
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
<table><tr><th>Exception</th><td>Test Exception</td></tr><tr><th>Last Occurrence</th><td>January 01, 1970 00:00:00 -0500</td></tr><tr><th>Count</th><td>1</td></tr></table>

## Stack Trace
<pre></pre>
Fingerprint: `abcdefg1234567890`
    BODY
        @rendered_issue.update_body(nil).must_equal expected_body
      end
    end
  end

  describe '#build_table_from_hash' do
    it 'builds an HTML table from a hash' do
      rendered_issue = PartyFoul::IssueRenderers::Base.new(nil, nil)
      hash = { 'Value 1' => 'abc', 'Value 2' => { 'Value A' => 123, 'Value B' => 456 } }
      expected = '<table><tr><th>Value 1</th><td>abc</td></tr><tr><th>Value 2</th><td><table><tr><th>Value A</th><td>123</td></tr><tr><th>Value B</th><td>456</td></tr></table></td></tr></table>'
      rendered_issue.build_table_from_hash(hash).must_equal expected
    end

    it 'escapes HTML entities' do
      rendered_issue = PartyFoul::IssueRenderers::Base.new(nil, nil)
      hash = { 'Value 1' => 'Error in #<Foo>' }
      expected = '<table><tr><th>Value 1</th><td>Error in #&lt;Foo&gt;</td></tr></table>'
      rendered_issue.build_table_from_hash(hash).must_equal expected
    end
  end

  describe '#fingerprint' do
    it 'SHA1s the title' do
      rendered_issue = PartyFoul::IssueRenderers::Base.new(nil, nil)
      rendered_issue.stubs(:title).returns('abcdefg1234567890')
      rendered_issue.fingerprint.must_equal Digest::SHA1.hexdigest(rendered_issue.title)
    end
  end

  describe '#occurred_at' do
    it 'memoizes the time' do
      rendered_issue = PartyFoul::IssueRenderers::Base.new(nil, nil)
      expected = rendered_issue.occurred_at
      Time.stubs(:now).returns(Time.new(1970, 1, 1, 0, 0, 1, '-05:00'))
      rendered_issue.occurred_at.must_equal expected
    end
  end

  describe '#title' do
    context 'when no title prefix is configured' do
      before do
        PartyFoul.configure do |config|
          config.title_prefix = nil
        end
      end

      it 'masks the object ids in the raw_title' do
        rendered_issue = PartyFoul::IssueRenderers::Base.new(nil, nil)
        rendered_issue.stubs(:raw_title).returns('Error for #<ClassName:0xabcdefg1234567>')
        rendered_issue.title.must_equal 'Error for #<ClassName:0xXXXXXX>'
      end

      it 'masks the extended object ids in the raw_title' do
        rendered_issue = PartyFoul::IssueRenderers::Base.new(nil, nil)
        rendered_issue.stubs(:raw_title).returns('Error for #<#<ClassName:0x007fbddbdcd340>:0x007fbddf6be0a0>')
        rendered_issue.title.must_equal 'Error for #<#<ClassName:0xXXXXXX>:0xXXXXXX>'
      end
    end

    context 'when a custom title prefix is configured' do
      before do
        PartyFoul.configure do |config|
          config.title_prefix = 'PRODUCTION'
        end
      end

      it 'adds a custom prefix' do
        rendered_issue = PartyFoul::IssueRenderers::Base.new(nil, nil)
        rendered_issue.stubs(:raw_title).returns('Error')
        rendered_issue.title.must_equal '[PRODUCTION] Error'
      end

      it 'generated unique fingerprints' do
        rendered_issue = PartyFoul::IssueRenderers::Base.new(nil, nil)
        rendered_issue.stubs(:raw_title).returns('Error')
        fingerprint = rendered_issue.fingerprint

        PartyFoul.configure do |config|
          config.title_prefix = 'STAGING'
        end

        fingerprint.wont_equal rendered_issue.fingerprint
      end
    end

    context 'title length limit' do
      before do
        PartyFoul.configure do |config|
          config.title_prefix = 'PRODUCTION'
        end
      end

      it 'at most 256 chars' do
        rendered_issue = PartyFoul::IssueRenderers::Base.new(nil, nil)
        rendered_issue.stubs(:raw_title).returns('F'*300)
        rendered_issue.title.size.must_equal 256
      end
    end
  end

  describe '#stack_trace' do
    # it 'returns the stack trace' do
      # exception = mock do
        # stubs backtrace: ['/path/to/gems/gem-name/lib/some/file.rb:123 in `method`']
      # end
      # rendered_issue = PartyFoul::IssueRenderers::Base.new(exception, nil)
      # rendered_issue.stack_trace.must_equal exception.backtrace.first
    # end

    it 'formats the stack trace with shortened bundle paths' do
      exception = mock do
        stubs backtrace: ["#{Bundler.bundle_path}/some_gem/lib/some/file.rb:123 in `method`"]
      end

      rendered_issue = PartyFoul::IssueRenderers::Base.new(exception, nil)
      rendered_issue.stack_trace.must_equal '[bundle].../some_gem/lib/some/file.rb:123 in `method`'
    end

    it 'formats the stack trace with link to shortened application path' do
      clean_up_party
      exception = mock do
        stubs backtrace: ['/path/to/app/lib/some/file.rb:123 in `method`']
      end
      rendered_issue = PartyFoul::IssueRenderers::Base.new(exception, nil)
      rendered_issue.stubs app_root: '/path/to/app'
      rendered_issue.stack_trace.must_match "<a href='https://github.com///blob//lib/some/file.rb#L123'>[app].../lib/some/file.rb:123 in `method`</a>"
    end

    it 'does not link to bundled resources on Heroku' do
      Bundler.stub(:bundle_path, '/app/vendor/bundle/ruby/2.0.0') do
        exception = mock do
          stubs backtrace: ["#{Bundler.bundle_path}/some_gem/lib/some/file.rb:123 in `method`"]
        end

        rendered_issue = PartyFoul::IssueRenderers::Base.new(exception, nil)
        rendered_issue.stubs app_root: '/app'
        rendered_issue.stack_trace.must_equal '[bundle].../some_gem/lib/some/file.rb:123 in `method`'
      end
    end
  end
end
