# -*- encoding: utf-8 -*-

require 'cgi'
require 'tempfile'
require 'rbconfig'

module Webgen
  class Tag

    # Executes the given command and returns the standard output. All special HTML characters are
    # escaped.
    module ExecuteCommand

      BIT_BUCKET = (RbConfig::CONFIG['host_os'] =~ /mswin|mingw/ ?  "nul" : "/dev/null")

      # Execute the command and return the standard output.
      def self.call(tag, body, context)
        command = context[:config]['tag.execute_command.command']
        output = `#{command} 2> #{BIT_BUCKET}`
        if $?.exitstatus != 0
          raise Webgen::RenderError.new("Command '#{command}' has return value != 0: #{output}",
                                        self.name, context.dest_node, context.ref_node)
        end
        output = CGI::escapeHTML(output) if context[:config]['tag.execute_command.escape_html']
        [output, context[:config]['tag.execute_command.process_output']]
      end

    end

  end
end
