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
require 'yaml'
require 'webgen/node'
require 'webgen/listener'
require 'webgen/languages'

module FileHandlers

  # The main plugin for handling files.
  #
  # The following message listening hooks (defined via symbols) are available for this plugin
  # (see Listener):
  #
  # +before_node_created+:: called before a node is created
  # +after_node_created+::  called after a node has been created
  # +after_all_nodes_created+:: called after the plugin has finfished reading in all files and the
  #                             output backing section of the meta information file has been processed
  # +before_node_written+:: called before a node is written out
  # +after_node_written+::  called after a node has been written out
  # +before_all_nodes_written+:: called before the plugin starts writing out the files
  # +after_all_nodes_written+:: called after the plugin has finfished writing out the files
  class FileHandler < Webgen::Plugin

    infos( :name => 'Core/FileHandler',
           :author => Webgen::AUTHOR,
           :summary => "Main plugin for handling the files in the source directory"
           )

    param 'ignorePaths', ['**/CVS{/**/**,/}'], 'An array of path patterns which match files ' +
      'that should be excluded from the list of \'to be processed\' files.'

    param 'defaultMetaInfo', {}, 'The keys for this hash are the names of file handlers, the ' +
      'values hashes with meta data.'

    depends_on 'Core/Configuration'

    include Listener

    def initialize( manager )
      super
      add_msg_name( :before_node_created )
      add_msg_name( :after_node_created )
      add_msg_name( :after_all_nodes_created )
      add_msg_name( :before_node_written )
      add_msg_name( :after_node_written )
      add_msg_name( :before_all_nodes_written )
      add_msg_name( :after_all_nodes_written )
      load_meta_info_backing_file
    end

    # Renders the whole website.
    def render_site
      tree = build_tree
      unless tree.nil?
        @plugin_manager['Misc/TreeWalker'].execute( tree )
        write_tree( tree )
      end
    end

    # Renders only the given +files+.
    def render_files( files )
      tree = build_tree
      return if tree.nil?
      files.each do |file|
        node = tree.resolve_node( file )
        if !node.nil?
          write_node( node.parent ) if !node.parent.nil? && node.parent.is_directory?
          write_node( node )
        end
      end
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

    # Returns the meta info for nodes for the given +handler+. If +file+ is specified, meta
    # information from the backing file is also used if available (using files specified in the
    # source block of the backing file). The parameter +file+ has to be an absolute path, ie.
    # starting with a slash.
    def meta_info_for( handler, file = nil )
      info = (handler.class.config.infos[:default_meta_info] || {}).dup
      info.update( param('defaultMetaInfo')[handler.class.plugin_name] || {} )
      if file
        file = normalize_path( file )
        if @source_backing.has_key?( file )
          info.update( @source_backing[file] )
        end
      end
      info
    end

    # Creates a node for +file+ (creating parent directories apropriately) under +parent_node+ using
    # the given +handler+. If a block is given, then the block is used to create the node which is
    # useful if you want a custom node creation method.
    def create_node( file, parent_node, handler ) # :yields: file, parent_node, handler, meta_info
      pathname, filename = File.split( file )
      parent_node = @plugin_manager['File/DirectoryHandler'].recursive_create_path( pathname, parent_node )

      meta_info = meta_info_for( handler, File.join( parent_node.absolute_path, filename ) )

      src_path = File.join( Node.root( parent_node ).node_info[:src], parent_node.absolute_path, filename )
      dispatch_msg( :before_node_created, src_path, parent_node, handler, meta_info )
      if block_given?
        node = yield( src_path, parent_node, handler, meta_info )
      else
        node = handler.create_node( src_path, parent_node, meta_info )
      end
      check_node( node ) unless node.nil?

      dispatch_msg( :after_node_created, node ) unless node.nil?


      node
    end

    #######
    private
    #######

    # Used to check that certain meta/node information is available and correct.
    def check_node( node )
      node['lang'] = Webgen::LanguageManager.language_for_code( node['lang'] ) unless node['lang'].kind_of?( Webgen::Language )
      node['title'] ||= node.path
    end

    # Returns a normalized path, ie. a path starting with a slash and any trailing slashes removed.
    def normalize_path( path )
      path = (path =~ /^\// ? '' : '/') + path.sub( /\/+$/, '' )
    end

    # Loads the meta information backing file from the website directory.
    def load_meta_info_backing_file
      file = File.join( param( 'websiteDir', 'Core/Configuration' ), 'metainfo.yaml' )
      if File.exists?( file )
        begin
          index = 1
          YAML::load_documents( File.read( file ) ) do |data|
            if data.nil? || (data.kind_of?( Hash ) && data.all? {|k,v| v.kind_of?( Hash ) })
              if index == 1
                @source_backing = {}
                data.each_pair {|path, metainfo| @source_backing[normalize_path(path)] = metainfo} unless data.nil?
              elsif index == 2
                @output_backing = data
              else
                log(:error) { "A backing file can only have two blocks: one for source and one for output backing!" }
              end
            else
              log(:error) { "Content of backing file (#{index == 1 ? 'source' : 'output'} block) not correctcly structured" }
            end
            index += 1
          end
        rescue
          log(:error) { "Backing file is not a valid YAML document: #{$!.message}" }
        end
      else
        log(:info) { 'No meta information backing file found!' }
      end
      @source_backing ||= {}
      @output_backing ||= {}
    end

    # Uses the output backing section of the meta information file to assign meta information or, if
    # no node for a path can be found, to create virtual nodes.
    def handle_output_backing( root )
      @output_backing.each do |path, data|
        path = path[1..-1] if path =~ /^\//
        if node = root.resolve_node( path )
          node.meta_info.update( data )
        else
          node = create_node( path, root, @plugin_manager['File/VirtualFileHandler'] ) do |src, parent, handler, meta_info|
            meta_info = meta_info.merge( data )
            handler.create_node( src, parent, meta_info )
          end
        end
        check_node( node )
      end
    end

    # Reads all files from the source directory and constructs the node tree which is returned.
    def build_tree
      all_files = find_all_files()
      return if all_files.empty?

      files_for_handlers = find_files_for_handlers()

      root_node = create_root_node()

      used_files = Set.new
      files_for_handlers.sort {|a,b| a[0] <=> b[0]}.each do |rank, handler, files|
        log(:debug) { "Creating nodes for #{handler.class.plugin_name} with rank #{rank}" }
        common = all_files & files
        used_files += common
        diff = files - common
        log(:info) { "Not using these files for #{handler.class.plugin_name} as they do not exist or are excluded: #{diff.inspect}" } if diff.length > 0
        common.each  do |file|
          log(:info) { "Creating node(s) for file <#{file}>..." }
          create_node( file.sub( /^#{root_node.node_info[:src]}/, '' ), root_node, handler )
        end
      end

      unused_files = all_files - used_files
      log(:info) { "No handlers found for: #{unused_files.inspect}" } if unused_files.length > 0

      handle_output_backing( root_node )
      dispatch_msg( :after_all_nodes_created, root_node )

      root_node
    end

    # Recursively writes out the tree specified by +node+.
    def write_tree( node )
      dispatch_msg( :before_all_nodes_written, node ) if node.parent.nil?

      write_node( node )
      node.each {|child| write_tree( child ) }

      dispatch_msg( :after_all_nodes_written, node ) if node.parent.nil?
    end

    # Writes out the given +node+.
    def write_node( node )
      log(:info) { "Writing <#{node.full_path}>" }
      dispatch_msg( :before_node_written, node )
      node.write_node
      dispatch_msg( :after_node_written, node )
    end

    # Creates a set of all files in the source directory, removing all files which should be ignored.
    def find_all_files
      all_files = files_for_pattern( '**/{**,**/}' ).to_set
      param( 'ignorePaths' ).each {|pattern| all_files.subtract( files_for_pattern( pattern ) ) }
      log(:error) { "No files found in the source directory <#{param('srcDir', 'Core/Configuration')}>" } if all_files.empty?
      all_files
    end

    # Finds the files for each registered handler plugin and stores them in a Hash with the plugin
    # as key.
    def find_files_for_handlers
      files_for_handlers = []
      @plugin_manager.plugins.each do |name, plugin|
        files_for_plugin = Set.new
        if plugin.kind_of?( DefaultHandler )
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
      files = Dir[File.join( param( 'srcDir', 'Core/Configuration' ), pattern )].to_set
      files.delete( File.join( param( 'srcDir', 'Core/Configuration' ), '/' ) )
      files.collect!  do |f|
        f = f.sub( /([^.])\.{1,2}$/, '\1' ) # remove '.' and '..' from end of paths
        f += '/' if File.directory?( f ) && ( f[-1] != ?/ )
        f
      end
      files
    end

    # Creates the root node.
    def create_root_node
      root_path = File.join( param( 'srcDir', 'Core/Configuration' ), '/' )
      root_handler = @plugin_manager['File/DirectoryHandler']
      if root_handler.nil?
        log(:error) { "No handler for root directory <#{root_path}> found" }
        return nil
      end

      root = root_handler.create_node( root_path, nil, meta_info_for( root_handler, '/' ) )
      root['title'] = ''
      root.path = File.join( param( 'outDir', 'Core/Configuration' ), '/' )
      root.node_info[:src] = root_path

      root
    end

  end


  # The default handler which is the super class of all file handlers. It defines methods thata
  # should be used by the subclasses to specify which files should be handled. There are two types
  # of path patterns: constant ones defined using the class methods and dynamic ones defined using
  # the instance methods. The dynamic path patterns should be defined during the initialization!
  #
  # During a webgen run the FileHandler retrieves all plugins which derive from the DefaultHandler
  # and uses the constant and dynamic path patterns defined for each file handler plugin for finding
  # the handled files.
  class DefaultHandler < Webgen::Plugin

    EXTENSION_PATH_PATTERN = "**/*.%s"
    DEFAULT_RANK = 100

    infos( :name => 'File/DefaultHandler',
           :author => Webgen::AUTHOR,
           :summary => "Base class of all file handler plugins",
           :instantiate => false
          )

    param 'linkToCurrentPage', false, 'Specifies whether in menus, breadcrumb trails, etc. a real link to ' +
      'the current page should be used or only the link text.'


    # Specify the path pattern which should be handled by the class. The +rank+ is used for sorting
    # the patterns so that the creation order of nodes can be influenced. If a file is matched by
    # more than one path pattern defined by a single file handler plugin, it is only used once for
    # the first pattern.
    def self.register_path_pattern( path, rank = DEFAULT_RANK )
      (self.config.infos[:path_patterns] ||= []) << [rank, path]
    end

    # Specify the files handled by the class via the extension. The parameter +ext+ should be the
    # pure extension without the dot. Also see DefaultHandler.register_path_pattern !
    def self.register_extension( ext, rank = DEFAULT_RANK )
      register_path_pattern( EXTENSION_PATH_PATTERN % [ext], rank )
    end

    # See DefaultHandler.register_path_pattern
    def register_path_pattern( path, rank = DEFAULT_RANK )
      (@path_patterns ||= []) << [rank, path]
    end
    protected :register_path_pattern

    # See DefaultHandler.register_extension
    def register_extension( ext, rank = DEFAULT_RANK )
      register_path_pattern( EXTENSION_PATH_PATTERN % [ext], rank )
    end
    protected :register_extension

    # Returns all (i.e. static and dynamic) path patterns defined for the file handler.
    def path_patterns
      (self.class.config.infos[:path_patterns] || []) + (@path_patterns ||= [])
    end

    # Sets the default meta information for the file handler. This meta information can later be
    # overridden by the +Core/FileHandler:defaultMetaInfo+ parameter and values set in the meta
    # information backing file. The so updated meta information is then passed to the #create_node
    # method.
    def self.default_meta_info( hash )
      self.config.infos[:default_meta_info] = hash
    end

    # Asks the plugin to create a node for the given +path+ and the +parent+, using +meta_info+ as
    # default meta data for the node. Should return the node for the path (the newly created node
    # or, if a node with the path already exists, the existing one) or +nil+ if the node could not
    # be created.
    #
    # Has to be overridden by the subclass!!!
    def create_node( path, parent, meta_info )
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

    # Returns a HTML link to the +node+ from +ref_node+ or, if +node+ and +ref_node+ are the same
    # and the parameter +linkToCurrentPage+ is +false+, a +span+ element with the link text.
    #
    # You can optionally specify additional attributes for the html element in the +attr+ Hash.
    # Also, the meta information +linkAttrs+ of the given +node+ is used, if available, to set
    # attributes. However, the +attr+ parameter takes precedence over the +linkAttrs+ meta
    # information. If the special value +:link_text+ is present in the attributes, it will be used
    # as the link text; otherwise the title of the +node+ will be used. Be aware that all key-value
    # pairs with Symbol keys are removed before the attributes are written. Therefore you always
    # need to specify general attributes with Strings!
    def link_from( node, ref_node, attr = {} )
      attr = node['linkAttrs'].merge( attr ) if node['linkAttrs'].kind_of?( Hash )
      link_text = attr[:link_text] || node['title']
      attr.delete_if {|k,v| k.kind_of?( Symbol )}

      use_link = ( node != ref_node || param( 'linkToCurrentPage' ) )
      attr['href'] = ref_node.route_to( node ) if use_link
      attrs = attr.collect {|name,value| "#{name.to_s}=\"#{value}\"" }.sort.unshift( '' ).join( ' ' )
      ( use_link ? "<a#{attrs}>#{link_text}</a>" : "<span#{attrs}>#{link_text}</span>" )
    end

  end


  # Handles virtual nodes created via the output backing section of the meta information backing
  # file.
  class VirtualFileHandler < DefaultHandler

    # A virtual node.
    class VirtualNode < ::Node

      # Overridden to also match the +reference+ path of the virtual node.
      def =~( path )
        md = /^(#{@path}|#{@node_info[:reference]})(?=#|$)/ =~ path
        ( md ? $& : nil )
      end

    end

    infos( :name => 'File/VirtualFileHandler',
           :author => Webgen::AUTHOR,
           :summary => 'Handles virtual files specified in the backing file'
           )

    def create_node( path, parent, meta_info )
      filename = File.basename( path )
      filename, reference = (meta_info['url'] ? [meta_info['url'], filename] : [filename, filename])

      # no need to check for an existing nodes, that is already done in FileHandler#handle_output_backing
      temp_node = VirtualNode.new( parent, reference )
      resolved_node = temp_node.resolve_node( filename )
      if resolved_node
        node = VirtualNode.new( parent, temp_node.route_to( resolved_node ) )
      else
        node = VirtualNode.new( parent, filename )
      end
      parent.del_child( temp_node )

      node.meta_info.update( meta_info )
      node.node_info[:reference] = reference
      node.node_info[:processor] = self
      node
    end

    def write_node( node )
      # nothing to write
    end

  end

end
