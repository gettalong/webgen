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

require 'rexml/document'
require 'webgen/plugins/filehandler/page'

module FileHandlers

  # Handles page description files written in XML. A typical XML page looks like this:
  #
  #   <?xml version="1.0" ?>
  #   <webgen>
  #     <title>Title of file</title>
  #     <inMenu>true</inMenu>
  #
  #     <content>
  #       <h1>This is the Homepage</h1> The content of the page file.
  #     </content>
  #   </webgen>
  class XMLPagePlugin < PagePlugin

    plugin "XML Page Handler"
    summary "Handles XML webpage description files"

    EXTENSION = 'xpage'

    def get_file_data( srcName )
      root = REXML::Document.new( File.new( srcName ) ).root

      data = Hash.new
      root.each_element( '/webgen/*' ) do |element|
        data[element.name] = element.text
      end
      data['content'] = ''
      root.elements['content'].each do
        |child| child.write( data['content'] )
      end

      return data
    end

  end

end
