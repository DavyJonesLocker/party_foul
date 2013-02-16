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
end
