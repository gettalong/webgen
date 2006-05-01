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

require 'webgen/plugins/filehandlers/filehandler'

module FileHandlers

  # Handles directories.
  class DirectoryHandler < DefaultFileHandler

    # Specialized node for a directory.
    class DirNode < Node

      def initialize( parent, path )
        super( parent, path )
        self['title'] = File.basename( path )
      end

      def []( name )
        process_dir_index if !self.meta_info.has_key?( 'indexFile' ) && name == 'indexFile'
        super
      end

      def process_dir_index
        indexFile = node_info[:processor]['indexFile']
        if indexFile.nil?
          self['indexFile'] = nil
        else
          node = resolve_node( indexFile )
          if node
            node_info[:processor].log(:info) { "Directory index file for <#{self.full_path}> => <#{node.full_path}>" }
            self['indexFile'] = node
          else
            node_info[:processor].log(:warn) { "No directory index file found for directory <#{self.full_path}>" }
            self['indexFile'] = nil
          end
        end
      end

    end


    infos :summary => "Handles directories"

    param 'indexFile', 'index.html', 'The default file name for the directory index page file.'

    handle_path_pattern '**/'

    # Returns a new DirNode.
    def create_node( path, parent )
      filename = File.basename( path )
      if parent.nil? || (node = parent.find {|child| child.is_directory? && filename + '/' == child.path }).nil?
        node = DirNode.new( parent, filename + '/' )
        node.node_info[:processor] = self
      end
      node
    end

    # Creates the directory (and all its parent directories if necessary).
    def write_node( node )
      FileUtils.makedirs( node.full_path ) unless File.exists?( node.full_path )
    end

    # Return the page node for the directory +node+ using the specified language +lang+. If an
    # index file is specified, then the its correct language node is returned, else +node+ is
    # returned.
    def node_for_lang( node, lang )
      langnode = node['indexFile'].node_for_lang( lang ) if node['indexFile']
      langnode || node
    end

    def link_from( node, refNode, attr = {} )
      lang_node = node.node_for_lang( refNode['lang'] )
      attr[:link_text] ||=  lang_node['directoryName'] || node['title']
      super( lang_node, refNode, attr )
    end

    # Recursively creates a given directory path starting from the path of +parent+ and returns the
    # bottom most directory node.
    def recursive_create_path( path, parent )
      path.split( File::SEPARATOR ).each do |pathname|
        case pathname
        when '.' then  #do nothing
        when '..' then parent = parent.parent
        else parent = create_node( pathname, parent )
        end
      end
      parent
    end

  end

end
