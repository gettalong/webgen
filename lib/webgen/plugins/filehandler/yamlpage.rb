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
require 'webgen/plugins/filehandler/page'

module FileHandlers

  # Handles page description files written in YAML. The structure of such a file should be like the
  # following example:
  #
  #  key1: value1
  #  key2: value2
  #  title: This will be the title of the file
  #  an other meta information: value of this item
  #
  #  content:
  #    This will be the content of this page file.
  #
  # You can specify any key:value pairs but you have to specify at least the content part.
  class YAMLPagePlugin < PagePlugin

    NAME = "YAML Page Handler"
    SHORT_DESC = "Handles YAML webpage description files"

    EXTENSION = 'ypage'


    def init
      child_init
    end


    def get_file_data( srcName )
      YAML::load( File.new( srcName ) )
    end

  end

  UPS::Registry.register_plugin YAMLPagePlugin

end
