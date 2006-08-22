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

require 'set'
require 'webgen/listener'
require 'webgen/languages'

module FileHandlers

  class FileHandler < Webgen::Plugin

    infos :summary => "Main plugin for handling the files in the source directory"

    param 'ignorePaths', ['**/CVS{/**/**,/}'], 'An array of path patterns which match files ' +
      'that should be excluded from the list of \'to be processed\' files.'

    include Listener

    def initialize( manager )
      super
      add_msg_name( :AFTER_ALL_READ )
      add_msg_name( :AFTER_ALL_WRITTEN )
    end

    def render_site
      tree = build_tree
      #TODO
      #transform tree???
      write_tree( tree ) unless tree.nil?
    end

    # Returns true if the file +src+ is newer than +dest+ and therefore has been modified since the
    # last execution of webgen. The +mtime+ values for the source and destination files are used to
    # find this out.
    def file_modified?( src, dest )
      if File.exists?( dest ) && ( File.mtime( src ) <= File.mtime( dest ) )
        log(:info) { "File is up to date: <#{dest}>" }
        return false
      else
        return true
      end
    end

    #######
    private
    #######

    def build_tree
      all_files = find_all_files()
      return if all_files.empty?

      files_for_handlers = find_files_for_handlers()

      root_node = create_root_node()

      used_files = Set.new
      files_for_handlers.sort {|a,b| a[0] <=> b[0]}.each do |rank, handler, files|
        log(:debug) { "Creating nodes for #{handler.class.name} with rank #{rank}" }
        common = all_files & files
        used_files += common
        diff = files - common
        log(:info) { "Not using these files for #{handler.class.name} as they do not exist or are excluded: #{diff.inspect}" } if diff.length > 0
        common.each {|file| create_node( file, root_node, handler ) }
      end
      dispatch_msg( :AFTER_ALL_READ, root_node ) #TODO necessary?

      unused_files = all_files - used_files
      log(:info) { "No handlers found for: #{unused_files.inspect}" } if unused_files.length > 0

      root_node
    end

    # Recursively writes out the tree specified by +node+.
    def write_tree( node )
      log(:info) { "Writing <#{node.full_path}>" }

      node.write_node

      node.each {|child| write_tree( child ) }

      dispatch_msg( :AFTER_ALL_WRITTEN ) if node.parent.nil?
    end

    # Creates a set of all files in the source directory, removing all files which should be ignored.
    def find_all_files
      all_files = files_for_pattern( '**/{**,**/}' ).to_set
      param( 'ignorePaths' ).each {|pattern| all_files.subtract( files_for_pattern( pattern ) ) }
      log(:error) { "No files found in the source directory <#{param('srcDir', 'CorePlugins::Configuration')}>" } if all_files.empty?
      all_files
    end

    # Finds the files for each registered handler plugin and stores them in a Hash with the plugin
    # as key.
    def find_files_for_handlers
      files_for_handlers = []
      @plugin_manager.plugins.each do |name, plugin|
        files_for_plugin = Set.new
        if plugin.kind_of?( DefaultFileHandler )
          plugin.path_patterns.each do |rank, pattern|
            files = files_for_pattern( pattern ) - files_for_plugin
            files_for_handlers << [rank, plugin, files ] unless files.empty?
            files_for_plugin += files
          end
        end
      end
      files_for_handlers
    end

    # Returns an array of files of the source directory matching +pattern+
    def files_for_pattern( pattern )
      files = Dir[File.join( param( 'srcDir', 'CorePlugins::Configuration' ), pattern )].to_set
      files.delete( File.join( param( 'srcDir', 'CorePlugins::Configuration' ), '/' ) )
      files.collect!  do |f|
        f = f.sub( /([^.])\.{1,2}$/, '\1' ) # remove '.' and '..' from end of paths
        f += '/' if File.directory?( f ) && ( f[-1] != ?/ )
        f
      end
      files
    end

    def create_root_node
      root_path = File.join( param( 'srcDir', 'CorePlugins::Configuration' ), '/' )
      root_handler = @plugin_manager['FileHandlers::DirectoryHandler']
      if root_handler.nil?
        log(:error) { "No handler for root directory <#{root_path}> found" }
        return nil
      end

      root = root_handler.create_node( root_path, nil )
      root['title'] = ''
      root.path = File.join( param( 'outDir', 'CorePlugins::Configuration' ), '/' )
      root.node_info[:src] = root_path

      root
    end

    def create_node( file, root, handler )
      dir_handler = @plugin_manager['FileHandlers::DirectoryHandler']
      pathname, filename = File.split( file.sub( /^#{root.node_info[:src]}/, '' ) )
      parent_node = dir_handler.recursive_create_path( pathname, root )

      log(:info) { "Trying to create node for <#{file}>..." }
      node = handler.create_node( file, parent_node )
      log(:info) { "Node for <#{file}> created" } unless node.nil?
      #TODO check node for correct lang and other things
      node
    end

  end

  # The default handler which is the super class of all file handlers. It defines class methods
  # which should be used by the subclasses to specify which files should be handled.
  class DefaultFileHandler < Webgen::Plugin

    EXTENSION_PATH_PATTERN = "**/*.%s"
    DEFAULT_RANK = 100

    infos(
          :summary => "Base class of all file handler plugins",
          :instantiate => false
          )

=begin
TODO move todoc
- two types of paths: constant paths defined in class, dynamic ones defined when initializing
  FileHandler retrieves all plugins which derive from DefaultFileHandler, uses constant + dynamic paths
- if a file is matched by more than one pattern defined by a single file handler, it is only used once
  for the first pattern
- patterns are sorted ascending using their rank and nodes are then created in this order
=end

    # TODO comment Specify the extension which should be handled by the class.
    def self.handle_path_pattern( path, rank = DEFAULT_RANK )
      (self.config.infos[:path_patterns] ||= []) << [rank, path]
    end

    # Specify the files handled by the class via the extension. The parameter +ext+ should be the
    # pure extension without the dot. Files in hidden directories (starting with a dot) are also
    # searched.
    def self.handle_extension( ext, rank = DEFAULT_RANK )
      handle_path_pattern( EXTENSION_PATH_PATTERN % [ext], rank )
    end

    # See DefaultFileHandler.handle_path_pattern
    def handle_path_pattern( path, rank = DEFAULT_RANK )
      (@path_patterns ||= []) << [rank, path]
    end
    protected :handle_path_pattern

    # See DefaultFileHandler.handle_extension
    def handle_extension( ext, rank = DEFAULT_RANK )
      handle_path_pattern( EXTENSION_PATH_PATTERN % [ext], rank )
    end
    protected :handle_extension

    # Returns all (i.e. static and dynamic) path patterns defined for the file handler.
    def path_patterns
      (self.class.config.infos[:path_patterns] || []) + (@path_patterns ||= [])
    end

    # Asks the plugin to create a node for the given +path+ and the +parent+. Should return the
    # node for the path or nil if the node could not be created.
    #
    # Has to be overridden by the subclass!!!
    def create_node( path, parent )
      raise NotImplementedError
    end

    # Asks the plugin to write out the node.
    #
    # Has to be overridden by the subclass!!!
    def write_node( node )
      raise NotImplementedError
    end

    # Returns the node which has the same data as +node+ but in language +lang+; or +nil+ if such a
    # node does not exist. The default behaviour assumes that +node+ has the data for all languages.
    def node_for_lang( node, lang )
      node
    end

    # Returns a HTML link to the +node+ from +refNode+. You can optionally specify additional
    # attributes for the <a>-Element in the +attr+ Hash. If the special value +:link_text+ is
    # present in +attr+, it will be used as the link text; otherwise the title of the +node+ will be
    # used.
    def link_from( node, refNode, attr = {} )
      link_text = attr[:link_text] || node['title']
      attr.delete( :link_text )
      attr.delete( 'href' )
      attr[:href] = refNode.route_to( node )
      attrs = attr.collect {|name,value| "#{name.to_s}=\"#{value}\"" }.sort.join( ' ' )
      "<a #{attrs}>#{link_text}</a>"
    end

  end

end
