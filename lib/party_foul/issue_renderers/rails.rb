class PartyFoul::IssueRenderers::Rails < PartyFoul::IssueRenderers::Rack
  # Rails params hash. Filtered parms are respected.
  #
  # @return [Hash]
  def params
    parameter_filter = ActionDispatch::Http::ParameterFilter.new(env["action_dispatch.parameter_filter"])
    if env['action_dispatch.request.parameters']
      return parameter_filter.filter(env['action_dispatch.request.parameters'])
    else
      return parameter_filter
    end
  end

  # Rails session hash. Filtered parms are respected.
  #
  # @return [Hash]
  def session
    parameter_filter = ActionDispatch::Http::ParameterFilter.new(env['action_dispatch.parameter_filter'])
    parameter_filter.filter(env['rack.session'] || { } )
  end

  # The timestamp when the exception occurred. Will use Time.current when available to record
  # the time with the proper timezone
  #
  # @return [String]
  def occurred_at
    @occurred_at ||= Time.current.strftime('%B %d, %Y %H:%M:%S %z')
  end

  private

  def app_root
    Rails.root.to_s
  end

  def raw_title
    parameters = env['action_dispatch.request.parameters']['action'] if env['action_dispatch.request.parameters']
    %{#{env['action_controller.instance'].class}##{parameters} (#{exception.class}) "#{exception.message}"}
  end
end
