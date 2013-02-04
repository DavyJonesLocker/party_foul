class PartyFoul::IssueRenderers::Rails < PartyFoul::IssueRenderers::Rack
  # Title for the issue comprised of Controller#action (exception) "message"
  #
  # @return [String]
  def title
    %{#{env['action_controller.instance'].class}##{env['action_dispatch.request.path_parameters']['action']} (#{exception.class}) "#{exception.message}"}
  end

  # Rails params hash. Filtered parms are respected.
  #
  # @return [Hash]
  def params
    parameter_filter = ActionDispatch::Http::ParameterFilter.new(env["action_dispatch.parameter_filter"])
    parameter_filter.filter(env['action_dispatch.request.path_parameters'])
  end

  # Rails session hash. Filtered parms are respected.
  #
  # @return [Hash]
  def session
    parameter_filter = ActionDispatch::Http::ParameterFilter.new(env['action_dispatch.parameter_filter'])
    parameter_filter.filter(env['rack.session'])
  end

  private

  def app_root
    Rails.root
  end
end
