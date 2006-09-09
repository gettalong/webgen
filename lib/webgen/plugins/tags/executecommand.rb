#
#--
#
# $Id$
#
# webgen: template based static website generator
# Copyright (C) 2004 Thomas Leitner
#
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU
# General Public License as published by the Free Software Foundation; either version 2 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
# even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with this program; if not,
# write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#
#++
#

require 'cgi'
require 'webgen/extcommand'
load_plugin 'webgen/plugins/tags/tag_processor'
load_plugin 'webgen/plugins/miscplugins/syntax_highlighter'

module Tags

  # Executes the given command and writes the standard output into the output file. All HTML special
  # characters are escaped.
  class ExecuteCommandTag < DefaultTag

    infos :summary => "Executes the given command and uses its standard output as the tag value"

    param 'command', nil, 'The command which should be executed'
    param 'processOutput', true, 'The output of the command will be further processed by the TagProcessor if true'
    param 'escapeHTML', true, 'Special HTML characters in the output will be escaped if true'
    param 'highlight', nil, 'Name of language that should be used for syntax highlighting ' +
      'the output of the command. If set to nil, no highlighting is performed. ' +
      "Available langs: #{MiscPlugins::SyntaxHighlighter.available_languages.sort.join(', ')}"
    set_mandatory 'command', true

    register_tag 'execute'

    def process_tag( tag, chain )
      @process_output = param( 'processOutput' )
      command = param( 'command' )
      if command
        cmd = ExtendedCommand.new( command )
        log(:debug) { "Executed command '#{command}', results: #{cmd.inspect}" }
        output = cmd.out_text
        if cmd.ret_code != 0
          log(:error) { "Command '#{command}' did not return with exit value 0: #{cmd.err_text}" }
        end
        output = CGI::escapeHTML( output ) if param( 'escapeHTML' )
        if !param( 'highlight' ).nil?
          output = @plugin_manager['Misc/SyntaxHighlighter'].highlight( output, param( 'highlight' ) )
        end
      end
      output
    end

  end

end
