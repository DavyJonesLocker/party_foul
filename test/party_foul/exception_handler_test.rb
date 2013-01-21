require 'test_helper'

describe 'Party Fould Exception Handler' do
  before do
    Time.stubs(:now).returns(Time.at(0))
  end

  describe 'updating issue body' do
    it 'updates count and timestamp' do
      body = <<-BODY
Count: 1
Last Occurance: #{Time.now}

Stack Trace:
  BODY

      Time.stubs(:now).returns(Time.new(1985, 10, 25, 1, 22, 0, '-05:00'))

      expected_body = <<-BODY
Count: 2
Last Occurance: #{Time.now}

Stack Trace:
  BODY

      handler = PartyFoul::ExceptionHandler.new(nil, nil)
      handler.update_body(body).must_equal expected_body
    end
  end
end
