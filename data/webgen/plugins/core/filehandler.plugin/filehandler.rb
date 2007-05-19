require 'set'
require 'yaml'
require 'ostruct'
require 'webgen/node'
require 'webgen/listener'
require 'webgen/languages'

module Core

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
  class FileHandler

    include Listener

    def initialize
      add_msg_name( :before_node_created )
      add_msg_name( :after_node_created )
      add_msg_name( :after_all_nodes_created )
      add_msg_name( :before_node_written )
      add_msg_name( :after_node_written )
      add_msg_name( :before_all_nodes_written )
      add_msg_name( :after_all_nodes_written )
      add_msg_name( :after_webgen_run )
    end

    def init_plugin
      load_meta_info_backing_file
    end

    # Returns the meta info for nodes for the given +handler+ name. If +file+ is specified, meta
    # information from the backing file is also used if available (using files specified in the
    # source block of the backing file). The parameter +file+ has to be an absolute path, ie.
    # starting with a slash.
    def meta_info_for( handler, file_struct = nil, file = nil )
      info = (@plugin_manager.plugin_infos.get( handler, 'file', 'meta_info' ) || {}).dup
      info.update( param('defaultMetaInfo')[handler] || {} )
      if file_struct
        info['lang'] = file_struct.lang
        info['orderInfo'] = file_struct.orderInfo
        info['title'] = file_struct.title
      end
      if file
        file = normalize_path( file )
        info.update( @source_backing[file] ) if @source_backing.has_key?( file )
      end
      info
    end

    # If there is already a node for the given +path+ under +parent_node+, the method returns this
    # node or +nil+ otherwise.
    def node_exist?( parent_node, path )
      path = path.chomp( '/' )
      node = parent_node.find {|n| n.path == path }
      if node
        log(:warn) { "There is already a node <#{node.full_path}>!" }
      end
      node
    end

    # Analyses the +filename+ and returns a struct with the extracted information.
    # Test: default.png, default.en.png, default.deu.png, default.template -> extension should always be correct!
    def analyse_filename( filename )
      analysed = OpenStruct.new
      analysed.filename  = filename
      matchData = /^(?:(\d+)\.)?([^.]*?)(?:\.(\w\w\w?)(?=.))?(?:\.(.*))?$/.match( File.basename( filename ) )

      analysed.orderInfo = matchData[1].to_i
      analysed.basename  = matchData[2]
      analysed.lang      = Webgen::LanguageManager.language_for_code( matchData[3] )
      analysed.ext       = matchData[4].to_s

      analysed.cn        = analysed.basename + (analysed.ext.length > 0 ? '.' + analysed.ext : '')
      analysed.title     = analysed.basename.tr('_-', ' ').capitalize

      log(:debug) { analysed.inspect }

      analysed
    end

    # Creates a node for +file+ (creating parent directories apropriately) under +parent_node+ using
    # the given +handler+. If a block is given, then the block is used to create the node which is
    # useful if you want a custom node creation method.
    def create_node( file, parent_node, handler ) # :yields: file_struct, parent_node, handler, meta_info
      pathname, filename = File.split( file )
      parent_node = @plugin_manager['File/DirectoryHandler'].recursive_create_path( pathname, parent_node )

      src_path = File.join( Node.root( parent_node ).node_info[:src], parent_node.absolute_path, filename )
      file_struct = analyse_filename( src_path )
      meta_info = meta_info_for( handler.plugin_name, file_struct, File.join( parent_node.absolute_path, filename ) )

      dispatch_msg( :before_node_created, file_struct, parent_node, handler, meta_info )
      if block_given?
        node = yield( file_struct, parent_node, handler, meta_info )
      else
        node = handler.create_node( file_struct, parent_node, meta_info )
      end
      check_node( node ) unless node.nil?

      dispatch_msg( :after_node_created, node ) unless node.nil?

      node
    end


    # TODO(document)
    def file_changed?( src_file, out_file=nil )
      s_mtime = File.mtime( src_file )
      c_mtime = @plugin_manager['Core/CacheManager'].get( [:files, src_file, :mtime], s_mtime )
      !c_mtime || s_mtime > c_mtime || (out_file && !File.exists?( out_file ))
    end

    # TODO(document)
    def node_changed?( node )
      file_changed = (node.node_info.has_key?( :src ) ?
                      file_changed?( node.node_info[:src], (node.node_info[:no_output] ? nil : node.full_path) ) :
                      false)
      change_proc = (node.node_info.has_key?( :change_proc ) ? node.node_info[:change_proc].call( node ) : false)
      metainfo_changed = (node.meta_info != @plugin_manager['Core/CacheManager'].get( [:nodes, node.absolute_path, :metainfo], node.meta_info ))
      log(:debug) { node.full_path + ': ' + [file_changed, change_proc, metainfo_changed].inspect }
      log(:debug) { node.full_path + ': ' + node.meta_info.inspect }
      file_changed || metainfo_changed || change_proc
    end

    # TODO(document) Should be used to write any file to the output directory.
    def write_path( dest, opts = {} )
      if opts[:src]
        if File.directory?( opts[:src] )
          FileUtils.makedirs( dest )
        else
          FileUtils.cp( opts[:src], dest )
        end
      else
        File.open( dest, 'wb' ) {|f| f.write( opts[:data] )}
      end
      @plugin_manager['Core/CacheManager'].add( [:files_written], dest )
    end


    # Renders the whole website.
    def render_site
      @plugin_manager.logger.level = param( 'loggerLevel', 'Core/Configuration' )
      log(:info) { "Starting rendering of website <#{param('websiteDir', 'Core/Configuration')}>..." }
      log(:info) { "Using webgen data directory at <#{Webgen.data_dir}>" }

      tree = build_tree
      unless tree.nil?
        #@plugin_manager['Misc/TreeWalker'].execute( tree ) TODO activate again!
        write_tree( tree )
      end
      dispatch_msg( :after_webgen_run )

      log(:info) { "Rendering of website <#{param('websiteDir', 'Core/Configuration')}> finished" }
    end

    # Reads all files from the source directory and constructs the node tree which is returned.
    def build_tree
      all_files = find_all_files()
      return if all_files.empty?

      files_for_handlers = find_files_for_handlers()

      root_node = create_root_node()

      used_files = Set.new
      files_for_handlers.sort {|a,b| a[0] <=> b[0]}.each do |rank, handler, files|
        log(:debug) { "Creating nodes for #{handler.plugin_name} with rank #{rank}" }
        common = all_files & files
        used_files += common
        diff = files - common
        log(:info) { "Not using these files for #{handler.plugin_name} as they do not exist or are excluded: #{diff.inspect}" } if diff.length > 0
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
      dispatch_msg( :before_node_written, node )
      changed = node_changed?( node )
      if changed && (info = node.write_info)
        log(:info) { "Writing <#{node.full_path}>" }
        write_path( node.full_path, info )
      else
        log(:info) { "Nothing to do for: <#{node.full_path}>" }
      end
      dispatch_msg( :after_node_written, node, changed )
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
          log(:info) { "Creating virtual node for path <#{path}>..." }
          node = create_node( path, root, @plugin_manager['File/VirtualFileHandler'] ) do |file_struct, parent, handler, meta_info|
            meta_info = meta_info.merge( data )
            handler.create_node( file_struct, parent, meta_info )
          end
        end
        check_node( node )
      end
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
      @plugin_manager.plugin_infos.keys.each do |name|
        files_for_plugin = Set.new
        if name =~ /^File\//
          plugin = @plugin_manager[name]
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

      file_struct = analyse_filename( root_path )
      root = root_handler.create_node( file_struct, nil, meta_info_for( root_handler, file_struct, '/' ) )
      root['title'] = ''
      root.path = File.join( param( 'outDir', 'Core/Configuration' ), '/' )
      root.node_info[:src] = root_path

      root
    end

  end

end
