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

require 'yaml'
require 'rdoc/markup/simple_markup'
require 'rdoc/markup/simple_markup/to_html'
require 'webgen/plugins/filehandler/page'

module FileHandlers

  # Handles files in RDoc format.
  class RDocPagePlugin < PagePlugin

    plugin "RDoc Page Handler"
    summary "Handles webpage description files in RDOC format"

    EXTENSION = 'rdoc'

    def initialize
      @processor = SM::SimpleMarkup.new
      @formatter = SM::ToHtml.new
    end

    def get_file_data( srcName )
      data = Hash.new
      data['content'] = @processor.convert( File.read( srcName ), @formatter )
      data
    end

  end

end
