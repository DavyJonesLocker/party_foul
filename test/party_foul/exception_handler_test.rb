require 'test_helper'

describe 'Party Fould Exception Handler' do
  before do
    Time.stubs(:now).returns(Time.at(0))
  end

  describe '#body' do
    describe 'updating issue body' do
      before do
        @handler = PartyFoul::ExceptionHandler.new(nil, nil)
        @handler.stubs(:fingerprint).returns('abcdefg1234567890')
        @handler.stubs(:stack_trace)
        @handler.stubs(:params)
        @handler.stubs(:exception)
      end

      it 'updates count and timestamp' do
        body = <<-BODY
<table>
<tr><th>Fingerprint</th><td>abcdefg1234567890</td><tr>
<tr><th>Count</th><td>1</td></tr>
<tr><th>Last Occurance</th><td>#{Time.now}</td></tr>
<tr><th>Params</th><td></td></tr>
<tr><th>Exception</th><td></td></tr>
</table>

## Stack Trace
<pre></pre>
    BODY

        Time.stubs(:now).returns(Time.new(1985, 10, 25, 1, 22, 0, '-05:00'))

        expected_body = <<-BODY
<table>
<tr><th>Fingerprint</th><td>abcdefg1234567890</td><tr>
<tr><th>Count</th><td>2</td></tr>
<tr><th>Last Occurance</th><td>#{Time.now}</td></tr>
<tr><th>Params</th><td></td></tr>
<tr><th>Exception</th><td></td></tr>
</table>

## Stack Trace
<pre></pre>
    BODY

        @handler.update_body(body).must_equal expected_body
      end
    end

    describe 'empty body' do
      before do
        @handler = PartyFoul::ExceptionHandler.new(nil, nil)
        @handler.stubs(:fingerprint).returns('abcdefg1234567890')
        @handler.stubs(:stack_trace)
        @handler.stubs(:params)
        @handler.stubs(:exception)
      end

      it 'resets body' do
        expected_body = <<-BODY
<table>
<tr><th>Fingerprint</th><td>abcdefg1234567890</td><tr>
<tr><th>Count</th><td>1</td></tr>
<tr><th>Last Occurance</th><td>#{Time.now}</td></tr>
<tr><th>Params</th><td></td></tr>
<tr><th>Exception</th><td></td></tr>
</table>

## Stack Trace
<pre></pre>
    BODY
        @handler.update_body(nil).must_equal expected_body
      end
    end
  end

  describe '#params' do
    context 'with Rails' do
      before do
        @handler = PartyFoul::ExceptionHandler.new(nil, {'action_dispatch.request.path_parameters' => { status: 'ok' }, 'QUERY_STRING' => { status: 'fail' } })
      end

      it 'returns ok' do
        @handler.params[:status].must_equal 'ok'
      end
    end

    context 'without Rails' do
      before do
        @handler = PartyFoul::ExceptionHandler.new(nil, {'QUERY_STRING' => { status: 'ok' } })
      end

      it 'returns ok' do
        @handler.params[:status].must_equal 'ok'
      end
    end
  end
end
