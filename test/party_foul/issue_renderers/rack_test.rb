require 'test_helper'

describe 'Rack Issue Renderer' do
  describe '#params' do
    before do
      @rendered_issue = PartyFoul::RackIssueRenderer.new(nil, {'QUERY_STRING' => { 'status' => 'ok' } })
    end

    it 'returns ok' do
      @rendered_issue.params['status'].must_equal 'ok'
    end
  end

  describe '#title' do
    before do
      @exception = Exception.new('message')
    end

    it 'constructs the title with the class and instance method' do
      @rendered_issue = PartyFoul::RackIssueRenderer.new(@exception, {})
      @rendered_issue.title.must_equal %{(Exception) "message"}
    end
  end
end
