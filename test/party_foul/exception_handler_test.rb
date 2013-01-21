require 'test_helper'

describe 'Party Fould Exception Handler' do
  before do
    Time.stubs(:now).returns(Time.at(0))
  end

  describe 'updating issue body' do
    before do
      @handler = PartyFoul::ExceptionHandler.new(nil, nil)
      @handler.stubs(:stack_trace)
      @handler.stubs(:params)
      @handler.stubs(:exception)
    end
    it 'updates count and timestamp' do
      body = <<-BODY
Count: 1
Last Occurance: #{Time.now}
Params: ``
Exception: ``
Stack Trace:
```
```
  BODY

      Time.stubs(:now).returns(Time.new(1985, 10, 25, 1, 22, 0, '-05:00'))

      expected_body = <<-BODY
Count: 2
Last Occurance: #{Time.now}
Params: ``
Exception: ``
Stack Trace:
```
```
  BODY

      handler = PartyFoul::ExceptionHandler.new(nil, nil)
      handler.update_body(body).must_equal expected_body
    end

    context 'when body is empty' do
      it 'resets body' do

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
