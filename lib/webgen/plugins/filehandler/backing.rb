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

require 'webgen/plugins/filehandler/filehandler'
require 'webgen/plugins/filehandler/directory'
require 'webgen/plugins/filehandler/page'

module FileHandlers

  class BackingFileHandler < DefaultFileHandler

    summary "Handles backing files for page file"
    extension 'info'
    depends_on 'FileHandler'

    def initialize
      super
      Webgen::Plugin['FileHandler'].add_msg_listener( :AFTER_ALL_READ, method( :process_backing_files ) )
    end

    def create_node( path, parent )
      node = Node.new( parent )
      node['src'] = node['dest'] = node['title'] = File.basename( path )
      node['backingFile'] = true
      begin
        node['content'] = YAML::load( File.new( path ) )
        if !valid_content( node['content'] )
          node['content'] = {}
          self.logger.error { "Content of backing file <#{backingFile.recursive_value( 'src' )}> not correctcly structured" }
        end
      rescue
        self.logger.error { "Content not correctly formatted (should be valid YAML) in backing file <#{path}>" }
      ensure
        node['content'] ||= {}
      end
      node['processor'] = self
      node
    end

    def write_node( node )
      # nothing to write
    end

    #######
    private
    #######

    def valid_content( data )
      data.kind_of?( Hash ) \
      && data.all? {|k,v| v.kind_of?( Hash ) }
    end

    def process_backing_files( dirNode )
      backingFiles = dirNode.find_all {|child| child['backingFile'] }

      backingFiles.each do |backingFile|
        backingFile['content'].each do |filename, data|
          if dirNode.node_for_string?( filename )
            backedFile = dirNode.node_for_string( filename )
            self.logger.info { "Setting meta info data on file <#{backedFile.recursive_value( 'dest' )}>" }
            backedFile.metainfo.update( data )
          else
            add_virtual_node( dirNode, filename, data )
          end
        end
      end

      dirNode.each {|child| process_backing_files( child ) if child['directory']}
    end


    def add_virtual_node( dirNode, path, data )
      dirname = File.dirname( path ).sub( /^.$/, '' )
      filename = File.basename( path )
      dirNode = create_path( dirname, dirNode )

      self.logger.debug { "Trying to create virtual node for '#{filename}'..." }
      pageNode = Webgen::Plugin['VirtualPageHandler'].create_node_from_data( '', filename, dirNode )
      dirNode.add_child( pageNode )
      pageNode.metainfo.update( data )
      self.logger.info { "Created virtual node <#{pageNode.recursive_value( 'src' )}> (#{pageNode['lang']}) in <#{dirNode.recursive_value( 'dest' )}> " \
        "referencing '#{pageNode['dest']}'" }
    end


    def create_path( dirname, dirNode )
      if /^#{File::SEPARATOR}/ =~ dirname
        node = Node.root( dirNode )
        dirname = dirname[1..-1]
      else
        node = dirNode
      end

      parent = node
      dirname.split( File::SEPARATOR ).each do |element|
        case element
        when '..'
          node = node.parent
        else
          node = node.find {|child| /^#{element}\/?$/ =~ child['src'] }
        end
        if node.nil?
          node = FileHandlers::DirHandler::DirNode.new( parent, element )
          node['processor'] = Webgen::Plugin['VirtualDirHandler']
          parent.add_child( node )
          self.logger.info { "Created virtual directory <#{node.recursive_value( 'dest' )}>" }
        end
        parent = node
      end

      return node
    end

  end


  # Handles virtual directories, that is, directories that do not exist in the source tree.
  class VirtualDirHandler < DirHandler

    summary "Handles virtual directories"
    depends_on "DirHandler"

    def write_node( node )
    end

  end

  # Handles virtual pages, that is, pages that do not exist in the source tree.
  class VirtualPageHandler < PageHandler

    summary "Handles virtual pages"
    depends_on "PageHandler"

    def write_node( node )
    end

  end

end
