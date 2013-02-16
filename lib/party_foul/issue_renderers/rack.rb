class PartyFoul::IssueRenderers::Rack < PartyFoul::IssueRenderers::Base
  def comment_options
    super.merge(URL: url, Params: params, Session: session, 'IP Address' => ip_address, 'HTTP Headers' => http_headers)
  end

  # Rack params
  #
  # @return [Hash]
  def params
    env['QUERY_STRING']
  end

  # IP address of the client who triggered the exception
  #
  # @return [String]
  def ip_address
    env['REMOTE_ADDR']
  end

  def url
    "[#{env['REQUEST_METHOD']}] #{env['REQUEST_URI']}"
  end

  # The session hash for the client at the time of the exception
  #
  # @return [Hash]
  def session
    env['rack.session']
  end

  # HTTP Headers hash from the request. Headers can be filtered out by
  # adding matching key names to {PartyFoul.blacklisted_headers}
  #
  # @return [Hash]
  def http_headers
    { Version: env['HTTP_VERSION'], 'User Agent' => env['HTTP_USER_AGENT'], 'Accept Encoding' => env['HTTP_ACCEPT_ENCODING'], Accept: env['HTTP_ACCEPT'] }
  end

  private

    # Title for the issue comprised of (exception) "message"
  #
  # @return [String]
  def raw_title
    %{(#{exception.class}) "#{exception.message}"}
  end
end
