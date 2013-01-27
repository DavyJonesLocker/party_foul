require 'party_foul/issue_renderer'

module PartyFoul
  class RackIssueRenderer < IssueRenderer
    def params
      env['QUERY_STRING']
    end

    def title
      %{(#{exception.class}) "#{exception.message}"}
    end
  end
end
