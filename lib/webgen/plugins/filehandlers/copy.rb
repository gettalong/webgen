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

  # A simple file handler which copies files with a specific extension from the source to the output
  # directory. The extensions of the files to copy are customizable.
  class CopyFileHandler < DefaultFileHandler

    summary "Copies files from source to destination without modification"
    add_param 'paths', ['**/*.css', '**/*.jpg', '**/*.png', '**/*.gif'], \
    'The path patterns which should match the files that should get copied by this handler.'
    depends_on 'FileHandler'

    def initialize
      super
      get_param( 'paths' ).each do |path|
        self.class.handle_path( path )
      end
    end

    def create_node( srcName, parent )
      node = Node.new( parent )
      node['dest'] = node['src'] = node['title'] = File.basename( srcName )
      node['processor'] = self
      node
    end

    # Copy the file to the destination directory if it has been modified.
    def write_node( node )
      if Webgen::Plugin['FileHandler'].file_modified?( node.recursive_value( 'src' ), node.recursive_value( 'dest' ) )
        FileUtils.cp( node.recursive_value( 'src' ), node.recursive_value( 'dest' ) )
      end
    end

  end

end
