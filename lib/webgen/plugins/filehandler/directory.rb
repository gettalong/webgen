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

require 'webgen/plugins/filehandler/filehandler'

module FileHandlers

  # Handles directories.
  class DirHandler < DefaultHandler

    # Specialized node describing a directory.
    class DirNode < Node

      def initialize( parent, name )
        super( parent )
        self['title'] = self['directoryName'] = name
        self['src'] = self['dest'] = name + '/'
        self['processor'] = Webgen::Plugin['DirectoryHandler']
      end

      def []( name )
        process_dir_index if super('indexFile').nil? && name == 'indexFile'
        super
      end

      def process_dir_index
        node = Webgen::Plugin['PageHandler'].get_page_node( Webgen::Plugin['DirectoryHandler']['indexFile'], self )
        if node
          self.logger.info { "Directory index file for <#{self.recursive_value( 'src' )}> => <#{node.recursive_value( 'src', false )}>" }
          self['indexFile'] = node
        else
          self.logger.warn { "No directory index file found for directory <#{self.recursive_value( 'src' )}>" }
          self['indexFile'] = nil
        end
      end

    end


    plugin "DirectoryHandler"
    summary "Handles directories"
    add_param 'indexFile', 'index.html', 'The default file name for the directory index file.'
    depends_on 'FileHandler'

    def initialize
      extension( :dir, DirHandler )
    end

    # Return a new DirNode.
    def create_node( path, parent )
      DirNode.new( parent, File.basename( path ) )
    end

    # Create the directory (and all its parent directories if necessary).
    def write_node( node )
      name = node.recursive_value( 'dest' )
      FileUtils.makedirs( name ) unless File.exists?( name )
    end

    # Return the language node for the directory +node+ using the specified language +lang+. If an
    # index file is specified, then the its correct language node is returned, else +node+ is
    # returned.
    def get_lang_node( node, lang = node['lang'] )
      if node['indexFile']
        node['indexFile']['processor'].get_lang_node( node['indexFile'], lang )
      else
        node
      end
    end

    # Get the HTML link for the directory +node+.
    def get_html_link( node, refNode, title = nil )
      lang_node = get_lang_node( node, refNode['lang'] )
      title ||=  lang_node['directoryName'] || node['directoryName']
      super( lang_node, refNode, title )
    end

  end

end
