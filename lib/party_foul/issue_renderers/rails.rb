class PartyFoul::IssueRenderers::Rails < PartyFoul::IssueRenderers::Rack
  # Rails params hash. Filtered parms are respected.
  #
  # @return [Hash]
  def params
    parameter_filter = ActionDispatch::Http::ParameterFilter.new(env["action_dispatch.parameter_filter"])
    parameter_filter.filter(env['action_dispatch.request.parameters'])
  end

  # Rails session hash. Filtered parms are respected.
  #
  # @return [Hash]
  def session
    parameter_filter = ActionDispatch::Http::ParameterFilter.new(env['action_dispatch.parameter_filter'])

    env_session = begin
      env['rack.session'].to_hash
    rescue NoMethodError
      env['rack.session'] || { }
    end

    parameter_filter.filter(env_session)
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
    %{#{env['action_controller.instance'].class}##{env['action_dispatch.request.parameters']['action']} (#{exception.class}) "#{exception.message}"}
  end
end
