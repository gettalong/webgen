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

  # Includes a file verbatim. All HTML special characters are escaped.
  class IncludeFileTag < DefaultTag

    infos :summary => "Includes a file verbatim"

    param 'filename', nil, 'The name of the file which should be included'
    param 'processOutput', true, 'The file content will be scanned for tags if true'
    param 'escapeHTML', true, 'Special HTML characters in the file content will be escaped if true'
    set_mandatory 'filename', true

    register_tag 'includeFile'

    def process_tag( tag, chain )
      @process_output = param( 'processOutput' )
      content = ''
      begin
        filename = File.join( chain.first.parent.node_info[:src], param( 'filename' ) )
        content = File.read( filename )
      rescue
        log(:error) { "Given file <#{filename}> specified in <#{chain.first.node_info[:src]}> does not exist or can't be read" }
      end
      content = CGI::escapeHTML( content ) if param( 'escapeHTML' )

      content
    end

  end

end
