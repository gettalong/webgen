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

require 'webgen/node'
require 'webgen/plugins/filehandler/filehandler'

module FileHandlers

  # Handles directories.
  class DirHandler < DefaultHandler

    # Specialized node describing a directory.
    class DirNode < Node


      def initialize( parent, name )
        super parent
        self['title'] = self['directoryName'] = name
        self['src'] = self['dest'] = name + File::SEPARATOR
      end


      def []( name )
        if name == 'indexFile' && !metainfo.has_key?( 'indexFile' )
          process_dir_index self
        end
        super
      end


      def process_dir_index( dirNode )
        node, created = Plugin['Page Handler'].get_page_node( indexFile, dirNode )
        if created
          self.logger.warn { "No directory index file found for directory <#{dirNode.recursive_value( 'src' )}>" }
          dirNode['indexFile'] = nil
        else
          self.logger.info { "Directory index file for <#{dirNode.recursive_value( 'src' )}> => <#{node['title']}>" }
          dirNode['indexFile'] = node
          node.each do |child| child['directoryName'] ||= dirNode['directoryName'] end
        end
      end


      def indexFile
        if !defined? @@indexFile
          item = Plugin['Directory Handler']['indexFile']
          @@indexFile = item.value
        end
        @@indexFile
      end
    end


    plugin "Directory Handler"
    summary "Handles directories"
    add_param 'indexFile','index.html', 'The default file name for the directory index file.'

    EXTENSION = :dir

    attr_reader :indexFile


    def create_node( path, parent )
      DirNode.new( parent, File.basename( path ) )
    end


    def write_node( node )
      name = node.recursive_value 'dest'
      FileUtils.makedirs( name ) unless File.exists? name
    end


    def get_lang_node( node, lang = node['lang'] )
      if node['indexFile']
        node['indexFile']['processor'].get_lang_node( node['indexFile'], lang )
      else
        node
      end
    end


    def get_html_link( node, refNode, title = nil )
      node = get_lang_node( node, refNode['lang'] )
      title ||=  node['directoryName']
      super( node, refNode, title )
    end

  end

end
