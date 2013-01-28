require 'party_foul/issue_renderer'

module PartyFoul
  class RailsIssueRenderer < IssueRenderer
    # Rails params hash. Filtered parms are respected.
    #
    # @return [Hash]
    def params
      parameter_filter = ActionDispatch::Http::ParameterFilter.new(env["action_dispatch.parameter_filter"])
      parameter_filter.filter(env['action_dispatch.request.path_parameters'])
    end

    # Title for the issue comprised of Controller#action (exception) "message"
    #
    # @return [String]
    def title
      %{#{env['action_controller.instance'].class}##{env['action_dispatch.request.path_parameters']['action']} (#{exception.class}) "#{exception.message}"}
    end

    private

    def app_root
      Rails.root
    end
  end
end
