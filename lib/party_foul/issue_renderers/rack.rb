require 'party_foul/issue_renderer'

module PartyFoul
  class RackIssueRenderer < IssueRenderer
    # Rack params
    #
    # @return [Hash]
    def params
      env['QUERY_STRING']
    end

    # Title for the issue comprised of (exception) "message"
    #
    # @return [String]
    def title
      %{(#{exception.class}) "#{exception.message}"}
    end
  end
end
