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
require 'webgen/plugins/tags/tags'

module Tags

  # Executes the given command and writes the standard output into the output file. All HTML special
  # characters are escaped.
  class ExecuteCommandTag < DefaultTag

    summary "Executes the given command and includes its standard output"
    depends_on 'Tags'
    add_param 'command', nil, 'The command which should be executed'
    add_param 'processOutput', true, 'The output of the command will be processed if true'
    add_param 'escapeHTML', true, 'Special HTML characters in the output will be escaped if true'
    set_mandatory 'command', true

    def initialize
      super
      register_tag( 'execute' )
    end

    def process_tag( tag, node, refNode )
      @processOutput = get_param( 'processOutput' )
      begin
        output = ( get_param( 'command' ) ? `#{get_param( 'command' )}` : '' )
      rescue StandardError => e
        output = ''
        logger.error { "Could not execute command #{get_param( 'command' )}: #{e.message}" }
      end
      output = CGI::escapeHTML( output ) if get_param( 'escapeHTML' )
      output
    end

  end

end
