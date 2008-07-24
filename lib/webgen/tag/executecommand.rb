require 'webgen/tag'
require 'cgi'
require "tempfile"

module Webgen::Tag

  # Executes the given command and returns the standard output. All special HTML characters are
  # escaped.
  class ExecuteCommand

    include Webgen::Tag::Base

    # Execute the command and return the standard output.
    def call(tag, body, context)
      command = param('tag.executecommand.command')
      output = `#{command} 2> /dev/null`
      if ($? >> 8) != 0
        raise "Command '#{command}' in <#{context.ref_node.absolute_lcn}> has return value != 0: #{output}"
      end
      output = CGI::escapeHTML(output) if param('tag.executecommand.escape_html')
      [output, param('tag.executecommand.process_output')]
    end

  end

end
