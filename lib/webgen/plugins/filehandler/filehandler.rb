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

require 'util/listener'

module FileHandlers

  # Super plugin for handling files. File handler plugins can register themselves by adding a new
  # key:value pair to +extensions+. The key has to be the extension in lowercase and the value is
  # the plugin object itself.
  class FileHandler < Webgen::Plugin

    summary "Super plugin for handling files"
    description "Provides interface on file level. The FileHandler goes through the source
        directory, reads in all files for which approriate plugins exist and
        builds the tree. When all approriate transformations on the tree have
        been performed the FileHandler is used to write the output files.
      ".gsub( /^\s+/, '' ).gsub( /\n/, ' ' )

    add_param 'ignored', ['.svn', 'CVS'], 'Specifies path names via regular expresssions which should be ignored.'


    include Listener

    attr_reader :extensions

    def initialize
      @extensions = Hash.new

      add_msg_name( :DIR_NODE_CREATED )
      add_msg_name( :FILE_NODE_CREATED )
      add_msg_name( :AFTER_DIR_READ )
    end


    # Recursively builds the tree with all the nodes and returns it.
    def build_tree
      root = build_entry( Webgen::Plugin['Configuration']['srcDirectory'], nil )
      unless root.nil?
        root['title'] = '/'
        root['dest'] = Webgen::Plugin['Configuration']['outDirectory'] + '/'
        root['src'] = Webgen::Plugin['Configuration']['srcDirectory'] + '/'
      end
      root
    end


    # Recursively writes out the tree specified by +node+.
    def write_tree( node )
      self.logger.info { "Writing <#{node.recursive_value('dest')}>" }

      node['processor'].write_node( node )

      node.each do |child|
        write_tree child
      end
    end


    # Returns true if the source file specified by +node+ has been modified since the last execution
    # of webgen. The +mtime+ values for the source and destination files are used to find this out.
    def file_modified?( node )
      src = node.recursive_value( 'src' )
      dest = node.recursive_value( 'dest' )
      if File.exists?( dest ) && ( File.mtime( src ) < File.mtime( dest ) )
        self.logger.info { "File is up to date: <#{dest}>" }
        return false
      else
        return true
      end
    end


    #######
    private
    #######

    def build_entry( path, parent )
      self.logger.info { "Processing <#{path}> ..." }

      if FileTest.file?( path )
        node = handle_file( path, parent )
      elsif FileTest.directory?( path )
        node = handle_directory( path, parent )
      else
        type = File.lstat( path ).ftype if File.exists?( path )
        self.logger.warn { "Path <#{path}> (type: #{type || 'non existing file/dir'}) cannot be handled as it is neither a file nor a directory" }
        node = nil
      end

      return node
    end


    def handle_file( path, parent )
      extension = File.extname( path ).sub( /^./, '' )

      if @extensions.has_key?( extension )
        node = @extensions[extension].create_node( path, parent )
        dispatch_msg( :FILE_NODE_CREATED, node ) unless node.nil?
      else
        self.logger.warn { "No plugin for <#{path}> (extension: #{extension}) -> ignored" }
      end

      return node
    end


    def handle_directory( path, parent )
      node = nil

      if @extensions.has_key?( :dir )
        node = @extensions[:dir].create_node( path, parent )

        dispatch_msg( :DIR_NODE_CREATED, node )

        Dir[path + File::SEPARATOR + '{.*,*}'].delete_if do |name|
          name =~ /#{File::SEPARATOR}.{1,2}$/ || \
          File.basename( name ) =~ Regexp.new( get_param( 'ignored' ).join( '|' ) )
        end.sort! do |a, b|
          if File.file?( a ) && File.directory?( b )
            -1
          elsif ( File.file?( a ) && File.file?( b ) ) || ( File.directory?( a ) && File.directory?( b ) )
            a <=> b
          else
            1
          end
        end.each do |filename|
          child = build_entry( filename, node )
          node.add_child( child ) unless child.nil?
        end

        dispatch_msg( :AFTER_DIR_READ, node )
      end

      return node
    end

  end

  # The default handler which is the super class of all file handlers.
  class DefaultHandler < Webgen::Plugin

    VIRTUAL = true

    summary "Base class of all file handler plugins"

    def initialize
      extension( Webgen::Plugin.config[self.class.name].extension ) if Webgen::Plugin.config[self.class.name].extension
    end

    # Register the file extension specified by a subclass.
    def extension( ext )
      self.logger.info { "Registering file handler #{self.class.name} (#{self.object_id}) with extension '#{ext}'" }
      Webgen::Plugin['FileHandler'].extensions[ext] = self
    end

    # Supplies the +path+ to a file and the +parent+ node sothat the plugin can create a node for this
    # path. Should return the node for the path or nil if the node could not be created.
    #
    # Has to be overridden by the subclass!!!
    def create_node( path, parent )
      raise "Not implemented"
    end

    # Asks the plugin to write out the node.
    #
    # Has to be overridden by the subclass!!!
    def write_node( node )
      raise "Not implemented"
    end

    # Returns the language node for the given +node+. The default implementation returns the node
    # itself. You can optionally specify the language of the node which should be returned. If not
    # specified the language of the node is used.
    def get_lang_node( node, lang = node['lang'] )
      node
    end

    # Returns a HTML link for the given +node+ relative to +refNode+. You can optionally specify the
    # title for the link. If not specified, the title of the node is used.
    def get_html_link( node, refNode, title = node['title'] )
      url = refNode.relpath_to_node( node )
      "<a href=\"#{url}\">#{title}</a>"
    end

  end

end
