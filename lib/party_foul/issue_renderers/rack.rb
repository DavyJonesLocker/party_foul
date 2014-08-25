class PartyFoul::IssueRenderers::Rack < PartyFoul::IssueRenderers::Base
    
  def request
    @request ||= ::Rack::Request.new(env)
  end      
  
  def comment_options
    super.merge(URL: url, Params: params, Session: session, 'IP Address' => ip_address_locator, 'HTTP Headers' => http_headers)
  end

  # Rack params
  #
  # @return [Hash]
  def params
    request.params
  end

  # Link to IP address geolocator of the client who triggered the exception
  #
  # @return [String]
  def ip_address_locator
    "<a href='http://ipinfo.io/#{request.ip}'>#{request.ip}</a>"
  end

  def url
    "[#{request.request_method}] #{env['REQUEST_URI']}"
  end

  # The session hash for the client at the time of the exception
  #
  # @return [Hash]
  def session
    request.session
  end

  # HTTP Headers hash from the request. Headers can be filtered out by
  # adding matching key names to {PartyFoul.blacklisted_headers}
  #
  # @return [Hash]
  def http_headers
    {
      Version: env['HTTP_VERSION'], 
      'User Agent' => request.user_agent, 
      'Accept Encoding' => env['HTTP_ACCEPT_ENCODING'], 
      Accept: env['HTTP_ACCEPT'], 
    }
  end

  private

  def raw_title
    %{(#{exception.class}) "#{exception.message}"}
  end
end
