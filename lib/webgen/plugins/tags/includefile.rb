#
#--
#
# $Id$
#
# webgen: a template based web page generator
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

    plugin "IncludeFileTag"
    summary "Includes a file verbatim"
    depends_on 'Tags'

    def initialize
      super
      register_tag( 'includeFile' )
      @processOutput = false
    end

    def check_mandatory_param( config )
      config.kind_of?( String )
    end

    def process_tag( tag, node, refNode )
      content = ''
      begin
        filename = refNode.parent.recursive_value( 'src' ) + get_param( :mandatory )
        self.logger.debug { "File location: <#{filename}>" }
        content = CGI::escapeHTML( File.open( filename, 'r' ).read )
      rescue
        self.logger.error { "Given file <#{filename}> does not exist (tag specified in <#{refNode.recursive_value( 'src' )}>" }
      end

      content
    end

  end

end
