require 'oauth2'

module PartyFoul
  class ExceptionHandler
    def self.handle(exception, env)
      return # Need to pull config from yaml file
      client = OAuth2::Client.new ClientId, ClientSecret, :site => 'https://api.github.com'

      access_token = OAuth2::AccessToken.new client, AccessToken
      debugger

      issue_body = <<-ISSUE
# Path

#{url_string(env)}

# Params

```
#{params_string(env)}
```

# Backtrace

#{linked_backtrace(exception.backtrace).join "\n"}

ISSUE
      line = exception.backtrace.select {|p| p =~ /#{Rails.root}/ }.first
      name_and_number = extract_file_name_and_line_number(line)[1]
      access_token.post "/repos/#{Owner}/#{Repo}/issues", :body => { :title => "#{exception.to_s} - #{name_and_number}", :body => issue_body }.to_json

    end

    def self.url_string(env)
      # Arguments are +scheme+, +userinfo+, +host+, +port+, +registry+, +path+,
      #     # +opaque+, +query+ and +fragment+, in that order.
      uri = URI::HTTP.new env['rack.url_scheme'], nil, env['SERVER_NAME'], env['SERVER_PORT'], nil, env['REQUEST_PATH'], nil, env['QUERY_STRING'], nil

      uri.to_s
    end

    def self.params_string(env)
      params = env['action_dispatch.request.parameters']

      params.map { |k,v| "#{k}=#{v}" }.join "\n"
    end

    def self.linked_backtrace(backtrace)
      backtrace.map do |line|
        if matches = extract_file_name_and_line_number(line)
          " * [#{line}](../tree/master/#{matches[2]}#L#{matches[3]}) "
        else
          " * #{line} "
        end
      end
    end

    def self.file_and_line_regex
      /#{Rails.root}\/((.+?):(\d+))/
    end

    def self.extract_file_name_and_line_number(backtrace_line)
      backtrace_line.match(file_and_line_regex)
    end
  end
end
