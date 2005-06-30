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

    summary "Includes a file verbatim"
    depends_on 'Tags'
    add_param 'filename', nil, 'The name of the file which should be included'
    add_param 'processOutput', true, 'The file content will be processed if true'
    add_param 'escapeHTML', true, 'Special HTML characters in the file content will be escaped if true'
    set_mandatory 'filename', true

    def initialize
      super
      register_tag( 'includeFile' )
    end

    def process_tag( tag, node, refNode )
      @processOutput = get_param( 'processOutput' )
      content = ''
      begin
        filename = refNode.parent_dir.recursive_value( 'src' ) + get_param( 'filename' )
        self.logger.debug { "File location: <#{filename}>" }
        content = File.read( filename )
      rescue
        self.logger.error { "Given file <#{filename}> does not exist (tag specified in <#{refNode.recursive_value( 'src' )}>" }
      end
      content = CGI::escapeHTML( content ) if get_param( 'escapeHTML' )

      content
    end

  end

end
