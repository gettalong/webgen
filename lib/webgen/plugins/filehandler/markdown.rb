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

require 'bluecloth'
require 'webgen/plugins/filehandler/page'

module ContentHandlers

  # Handles text formatted in Markdown format using BlueCloth.
  class MarkdownHandler < ContentHandler

    plugin "MarkdownHandler"
    summary "Handles content formatted in Markdown format using BlueCloth"
    depends_on "PageHandler"

    def initialize
      register_format( 'markdown' )
    end

    def format_content( txt )
      BlueCloth.new( txt ).to_html
    rescue
      self.logger.error { "Error converting Markdown text to HTML" }
      ''
    end

  end

end
