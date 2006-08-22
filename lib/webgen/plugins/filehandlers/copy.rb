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

require 'fileutils'
require 'webgen/plugins/filehandlers/filehandler'

module FileHandlers

  # A simple file handler which copies files specified by a pattern from the source to the output
  # directory.
  class FileCopyHandler < DefaultFileHandler

    infos :summary => "Copies files from source to destination without modification"
    param 'paths', ['**/*.css', '**/*.jpg', '**/*.png', '**/*.gif'], \
    'The path patterns which match the files that should get copied by this handler.'

    def initialize( plugin_manager )
      super
      param( 'paths' ).each {|path| register_path_pattern( path ) }
    end

    def create_node( path, parent )
      name = File.basename( path )
      node = parent.find {|c| c.path == name }
      if node.nil?
        node = Node.new( parent, name )
        node.node_info[:src] = path
        node.node_info[:processor] = self
        node['title'] = name
      else
        log(:warn) { "Can't create node <#{node.full_path}> as it already exists! Using existing!" }
      end
      node
    end

    # Copy the file to the destination directory if it has been modified.
    def write_node( node )
      if @plugin_manager['FileHandlers::FileHandler'].file_modified?( node.node_info[:src], node.full_path )
        node.parent.write_node
        FileUtils.cp( node.node_info[:src], node.full_path )
      end
    end

  end

end
