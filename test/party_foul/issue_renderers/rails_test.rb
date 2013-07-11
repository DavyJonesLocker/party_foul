require 'test_helper'

describe 'Rails Issue Renderer' do
  describe '#params' do
    before do
      @rendered_issue = PartyFoul::IssueRenderers::Rails.new(nil, {'action_dispatch.parameter_filter' => ['password'], 'action_dispatch.request.path_parameters' => { 'status' => 'ok', 'password' => 'test' }, 'QUERY_STRING' => { 'status' => 'fail' } })
    end

    it 'returns ok' do
      @rendered_issue.params['status'].must_equal 'ok'
      @rendered_issue.params['password'].must_equal '[FILTERED]'
    end
  end

  describe '#session' do
    let(:params) { {'action_dispatch.parameter_filter' => ['password'], 'rack.session' => { 'status' => 'ok', 'password' => 'test' }, 'QUERY_STRING' => { 'status' => 'fail' } } }

    before do
      @rendered_issue = PartyFoul::IssueRenderers::Rails.new(nil, params)
    end

    it 'returns ok' do
      @rendered_issue.session['status'].must_equal 'ok'
      @rendered_issue.session['password'].must_equal '[FILTERED]'
    end

    context "without session" do

      let(:params) { {'action_dispatch.parameter_filter' => ['password'], 'QUERY_STRING' => { 'status' => 'fail' } } }

      it 'returns empty hash' do
        @rendered_issue.session.must_be_empty
      end
    end


  end

  describe '#raw_title' do
    before do
      @exception = Exception.new('message')
      controller_instance = mock('Controller')
      controller_instance.stubs(:class).returns('LandingController')
      env = {
        'action_dispatch.request.path_parameters' => { 'controller' => 'landing', 'action' => 'index' },
        'action_controller.instance' => controller_instance
      }
      @rendered_issue = PartyFoul::IssueRenderers::Rails.new(@exception, env)
    end

    it 'constructs the title with the controller and action' do
      @rendered_issue.send(:raw_title).must_equal %{LandingController#index (Exception) "message"}
    end
  end
end
