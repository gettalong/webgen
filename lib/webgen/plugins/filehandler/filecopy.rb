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

require 'fileutils'
require 'webgen/plugins/filehandler/filehandler'

module FileHandlers

  # A simple file handler which copies files with a specific extension from the source to the output
  # directory. The extensions of the files to copy are customizable.
  class FileCopyPlugin < DefaultHandler

    NAME = "File Copy Handler"
    SHORT_DESC = "Copies files from source to destination without modification"
    DESCRIPTION = <<-EOF.gsub( /^\s*/, '' ).gsub( /\n/, ' ' )
        Implements a generic file copy plugin. All the file types which are specified in the
        configuration file are copied without any transformation into the destination directory.
      EOF


    CONFIG_PARAMS = [
      {
        :name => 'types',
        :defaultValue => ['css', 'jpg', 'png', 'gif'],
        :description => 'The extension that will be registered by this handler. All files with ' \
        + 'these extensions will be copied from the source to the destination folder.'
      }
    ]

    def init
      unless get_config_param( 'types' ).nil?
        get_config_param( 'types' ).each do |type|
          UPS::Registry['File Handler'].extensions[type] ||= self
        end
      end
    end


    def create_node( srcName, parent )
      relName = File.basename srcName
      node = Node.new parent
      node['dest'] = node['src'] = node['title'] = relName
      node
    end


    def write_node( node )
      FileUtils.cp( node.recursive_value( 'src' ), node.recursive_value( 'dest' ) ) if UPS::Registry['File Handler'].file_modified?( node )
    end

  end

  UPS::Registry.register_plugin FileCopyPlugin

end
