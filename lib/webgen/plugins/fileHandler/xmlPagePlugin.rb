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
require 'webgen/plugins/fileHandler/pagePlugin'

module FileHandlers

  class XMLPagePlugin < PagePlugin

    NAME = "XML Page Plugin"
    SHORT_DESC = "Handles XML webpage description files"

    EXTENSION = 'xpage'


    def init
      child_init
    end


    def get_file_data( srcName )
      root = REXML::Document.new( File.new( srcName ) ).root

      #TODO rework this sothat arbitrary tags can be included
      data = Hash.new
      data['title'] = root.text( '/webgen/title' )
      data['templateFile'] = root.text('/webgen/template') unless root.text('/webgen/template').nil?
      data['inMenu'] = root.text('/webgen/inMenu') unless root.text('/webgen/inMenu').nil?
      data['menuOrder'] = root.text('/webgen/menuOrder').to_i unless root.text('/webgen/menuOrder').nil?
      data['content'] = ''
      root.elements['content'].each do
        |child| child.write( data['content'] )
      end

      return data
    end

  end

  UPS::Registry.register_plugin XMLPagePlugin

end
