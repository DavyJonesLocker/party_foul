class PartyFoul::IssueRenderers::Base
  attr_accessor :exception, :env, :sha

  # A new renderer instance for GitHub issues
  #
  # @param [Exception, Hash]
  def initialize(exception, env)
    self.exception = exception
    self.env       = env
  end

  # Derived title of the issue. Must be implemented by the adapter class
  #
  # @return [NotImplementedError]
  def title
    raise NotImplementedError
  end

  # Renders the issue body
  #
  # Customize by overriding {#body_options}
  #
  # @return [String]
  def body
    <<-BODY
#{build_table_from_hash(body_options)}

## Stack Trace
<pre>#{stack_trace}</pre>
Fingerprint: `#{fingerprint}`
BODY
  end

  # Renderes the issue comment
  #
  # Customize by overriding {#comment_options}
  #
  def comment
    build_table_from_hash(comment_options)
  end

  # Compiles the stack trace for use in the issue body. Lines in the
  # stack trace that are part of the application will be rendered as
  # links to the relative file and line on GitHub based upon
  # {PartyFoul.web_url}, {PartyFoul.owner}, {PartyFoul.repo}, and
  # {PartyFoul.branch}. The branch will be used at the time the
  # exception happens to grab the SHA for that branch at that time for
  # the purpose of linking.
  #
  # @return [String]
  def stack_trace
    exception.backtrace.map do |line|
      if matches = extract_file_name_and_line_number(line)
        "<a href='#{PartyFoul.repo_url}/blob/#{sha}/#{matches[2]}#L#{matches[3]}'>#{line}</a>"
      else
        line
      end
    end.join("\n")
  end

  # A SHA1 hex digested representation of the title. The fingerprint is
  # used to create a unique value in the issue body. This value is used
  # for seraching when matching issues happen again in the future.
  #
  # @return [String]
  def fingerprint
    Digest::SHA1.hexdigest(title)
  end

  # Will update the issue body. The count and the time stamp will both
  # be updated. If the format of the issue body fails to match for
  # whatever reason the issue body will be reset.
  #
  # @return [String]
  def update_body(old_body)
    begin
      current_count = old_body.match(/<th>Count<\/th><td>(\d+)<\/td>/)[1].to_i
      old_body.sub!("<th>Count</th><td>#{current_count}</td>", "<th>Count</th><td>#{current_count + 1}</td>")
      old_body.sub!(/<th>Last Occurrence<\/th><td>.+<\/td>/, "<th>Last Occurrence</th><td>#{occurred_at}</td>")
      old_body
    rescue
      self.body
    end
  end

  # The timestamp when the exception occurred.
  #
  # @return [String]
  def occurred_at
    Time.now.strftime('%B %d, %Y %H:%M:%S %z')
  end

  # The hash used for building the table in issue body
  #
  # @return [Hash]
  def body_options(count = 0)
    { Exception: exception, 'Last Occurrence' => occurred_at, Count: count + 1 }
  end

  # The hash used for building the table in the comment body
  #
  # @return [Hash]
  def comment_options
    { 'Occurred At' => occurred_at }
  end


  # Builds an HTML table from hash
  #
  # @return [String]
  def build_table_from_hash(hash)
    "<table>#{rows_for_table_from_hash(hash)}</table>"
  end

  # Builds the rows of an HTML table from hash.
  # Keys as Headers cells and Values as Data cells
  # If the Value is a Hash it will be rendered as a table
  #
  # @return [String]
  def rows_for_table_from_hash(hash)
    hash.inject('') do |rows, row|
      key, value = row
      if row[1].kind_of?(Hash)
        value = build_table_from_hash(row[1])
      end
      rows << "<tr><th>#{key}</th><td>#{value}</td></tr>"
    end
  end

  # Provides additional labels using the configured options
  #
  # @return [Array]
  def labels
    if PartyFoul.additional_labels.respond_to? :call
      PartyFoul.additional_labels.call(self.exception, self.env) || []
    else
      PartyFoul.additional_labels || []
    end
  end

  private

  def app_root
    Dir.pwd
  end

  def extract_file_name_and_line_number(backtrace_line)
    backtrace_line.match(/#{app_root}\/((.+?):(\d+))/)
  end
end
