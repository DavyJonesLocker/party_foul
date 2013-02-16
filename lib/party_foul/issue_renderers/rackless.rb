require 'party_foul/issue_renderers/base'

class PartyFoul::IssueRenderers::Rackless < PartyFoul::IssueRenderers::Base
  # env in a rackless environment is expected to contain three keys:
  # class: name of the class that raised the exception
  # method: name of the method that raised the exception
  # params: parameters passed to the method that raised the exception

  # Rails params hash. Filtered parms are respected.
  #
  # @return [Hash]
  def params
    env[:params]
  end

  def comment_options
    super.merge(Params: params)
  end

  private

  def raw_title
    %{#{env[:class]}##{env[:method]} (#{exception.class}) "#{exception.message}"}
  end
end
