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

require 'rdoc/markup/simple_markup'
require 'rdoc/markup/simple_markup/to_html'
require 'webgen/plugins/filehandler/pagehandler/page'

module ContentHandlers

  # Handles text in RDoc format.
  class RDocContentHandler < ContentHandler

    summary "Handles content in RDOC format"
    depends_on "PageHandler"

    def initialize
      register_format( 'rdoc' )
      @processor = SM::SimpleMarkup.new
      @formatter = SM::ToHtml.new
    end

    def format_content( txt )
      @processor.convert( txt, @formatter )
    rescue
      self.logger.error { "Error converting RDOC text to HTML" }
      ''
    end

  end

end
