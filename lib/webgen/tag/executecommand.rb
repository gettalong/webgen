# -*- encoding: utf-8 -*-

require 'cgi'
require 'tempfile'
require 'rbconfig'

module Webgen::Tag

  # Executes the given command and returns the standard output. All special HTML characters are
  # escaped.
  class ExecuteCommand

    include Webgen::Tag::Base

    BIT_BUCKET = (RbConfig::CONFIG['host_os'] =~ /mswin|mingw/ ?  "nul" : "/dev/null")

    # Execute the command and return the standard output.
    def call(tag, body, context)
      command = param('tag.executecommand.command')
      output = `#{command} 2> #{BIT_BUCKET}`
      if $?.exitstatus != 0
        raise Webgen::RenderError.new("Command '#{command}' has return value != 0: #{output}",
                                      self.class.name, context.dest_node, context.ref_node)
      end
      output = CGI::escapeHTML(output) if param('tag.executecommand.escape_html')
      [output, param('tag.executecommand.process_output')]
    end

  end

end
