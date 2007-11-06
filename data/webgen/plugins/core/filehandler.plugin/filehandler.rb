require 'set'
require 'yaml'
require 'ostruct'
require 'webgen/node'
require 'webgen/listener'
require 'webgen/languages'

module Core

  # The main webgen plugin for handling files and rendering a webgen website.
  #
  # = Main functionality
  #
  # The rendering of a website is initiated by calling the #render_website method. The plugin
  # retrieves all plugins in the category <tt>File/</tt> which are assumed to be file handler
  # plugins and uses the defined path patterns defined for each file handler plugin for finding the
  # handled files. It then uses the file handler plugins to create nodes from the source files and
  # builds the internal representation: the node tree.
  #
  # After every file has been processed in this way, the node tree is traversed and each node is
  # written to the its destination location if it has changed since the last run.
  #
  # = Message Hooks
  #
  # The following message listening hooks (defined via symbols) are available for this plugin
  # (also see Listener):
  #
  # +before_node_created+::      called before a node is created
  # +after_node_created+::       called after a node has been created
  # +after_all_nodes_created+::  called after the plugin has finfished reading in all files and the
  #                              output backing section of the meta information file has been processed
  # +before_node_written+::      called before a node is written out
  # +after_node_written+::       called after a node has been written out
  # +before_all_nodes_written+:: called before the plugin starts writing out the files
  # +after_all_nodes_written+::  called after the plugin has finfished writing out the files
  # +after_website_rendered+::   called after the whole website has been rendered
  class FileHandler

    # Contains all information about one handled file.
    class FileInfo

      # The source filename (the analysed filename)
      attr_accessor :filename
      # The basename of the filename.
      attr_accessor :basename
      # The file extension.
      attr_accessor :ext

      # The meta information for the file.
      attr_accessor :meta_info

      def initialize( filename )
        @meta_info = {}
        analyse_filename( filename )
      end

      # The canonical name created from the filename (created from basename and extension).
      def cn
        @basename + (@ext.length > 0 ? '.' + @ext : '')
      end

      # The localized canonical name created from the filename.
      def lcn
        Node.lcn( cn, @meta_info['lang'] )
      end

      #######
      private
      #######

      # Analyses the +filename+ and fills the object with the extracted information.
      def analyse_filename( filename )
        self.filename = filename
        matchData = /^(?:(\d+)\.)?([^.]*?)(?:\.(\w\w\w?)(?=.))?(?:\.(.*))?$/.match( File.basename( filename ) )

        self.meta_info['orderInfo'] = matchData[1].to_i
        self.basename               = matchData[2]
        self.meta_info['lang']      = Webgen::LanguageManager.language_for_code( matchData[3] )
        self.ext                    = (self.meta_info['lang'].nil? && !matchData[3].nil? ? matchData[3].to_s + '.' : '') + matchData[4].to_s

        self.meta_info['title']     = self.basename.tr('_-', ' ').capitalize
      end
    end

    include Listener

    # Creates a new FileHandler plugin instance.
    def initialize
      add_msg_name( :before_node_created )
      add_msg_name( :after_node_created )
      add_msg_name( :after_all_nodes_created )
      add_msg_name( :before_node_written )
      add_msg_name( :after_node_written )
      add_msg_name( :before_all_nodes_written )
      add_msg_name( :after_all_nodes_written )
      add_msg_name( :after_website_rendered )
    end

    # During the initialisation, the meta information backing file is loaded. This method is
    # automatically called by the plugin framework.
    def init_plugin
      load_meta_info_backing_file
    end

    # Returns the meta info for nodes for the given +handler+ name. If +file_info+ is specified, the
    # meta information of +file_info+ is used to update the meta information (results in an update
    # from the meta information +lang+, +orderInfo+ and +title+ and probably others). If +file+ is
    # specified, meta information from the backing file is also used if available (using the paths
    # specified in the source block of the backing file). The parameter +file+ has to be an absolute
    # path, ie.  starting with a slash.
    def meta_info_for( handler, file_info = nil, file = nil )
      info = (@plugin_manager.plugin_infos.get( handler, 'file', 'meta_info' ) || {}).dup
      info.update( param('defaultMetaInfo')[handler] || {} )
      info.update( file_info.meta_info ) if file_info
      if file
        file = normalize_path( file )
        info.update( @source_backing[file] ) if @source_backing.has_key?( file )
      end
      info
    end

    # Creates a node for +file+ (creating parent directories apropriately) under +parent_node+ using
    # the given +handler+. If a block is given, then the block is used to create the node which is
    # useful if you want to use a custom node creation method.
    #
    # Returns one of the following:
    # * +nil+ if no node has been created by the +handler+
    # * a single node
    # * an array of nodes
    #
    # Attention: This method has to be used by any plugin that needs to create a node!
    def create_node( file, parent_node, handler ) # :yields: file_struct, parent_node, handler, meta_info
      pathname, filename = File.split( file )
      parent_node = @plugin_manager['File/DirectoryHandler'].recursive_create_path( pathname, parent_node )

      src_path = File.join( Node.root( parent_node ).node_info[:src], parent_node.absolute_path, filename )
      file_info = FileInfo.new( src_path )
      file_info.meta_info.update( meta_info_for( handler.plugin_name, file_info, File.join( parent_node.absolute_path, filename ) ) )

      dispatch_msg( :before_node_created, file_info, parent_node, handler )
      if block_given?
        nodes = yield( parent_node, file_info, handler )
      else
        nodes = handler.create_node( parent_node, file_info )
      end

      unless nodes.nil?
        [nodes].flatten.each do |node|
          check_node( node )
          dispatch_msg( :after_node_created, node ) unless node.nil?
        end
      end

      nodes
    end

    # Checks if the file +src_file+ has been modified since the last webgen run. If +out_file+ is
    # specified and does not exist, this method also returns +true+.
    def file_changed?( src_file, out_file=nil )
      s_mtime = File.mtime( src_file )
      c_mtime = @plugin_manager['Core/CacheManager'].get( [:files, src_file, :mtime], s_mtime )
      !c_mtime || s_mtime > c_mtime || (out_file && !File.exists?( out_file ))
    end

    # Checks if the meta information of the node has changed since the last webgen run.
    def meta_info_changed?( node )
      if !node.node_info.has_key?(:node_meta_info_changed)
        node.node_info[:node_meta_info_changed] =
          (node.meta_info != @plugin_manager['Core/CacheManager'].get( [:nodes, node.absolute_lcn, :metainfo], node.meta_info ))
      end
      node.node_info[:node_meta_info_changed]
    end

    # Checks if the +node+ has changed by executing three checks:
    #
    # * checks if the file has changed using file_changed? if the node has a <tt>:src</tt> node
    #   information (set <tt>node.node_info[:no_output_file]</tt> to true to not check for the
    #   existence of the output file)
    # * checks if an optionally associated change method is available through the
    #   <tt>:change_proc</tt> node information and executes it
    # * checks if the meta information for the node has changed since the last run
    #
    # Returns +true+ if any one of these three checks returns +true+.
    def node_changed?( node )
      if !node.node_info.has_key?(:node_changed)
        file_changed = (node.node_info.has_key?( :src ) ?
                        file_changed?( node.node_info[:src], (node.node_info[:no_output_file] ? nil : node.full_path) ) :
                        false)
        change_proc = (node.node_info.has_key?( :change_proc ) ? node.node_info[:change_proc].call( node ) : false)
        metainfo_changed = meta_info_changed?( node )

        log(:debug) { node.full_path + ': ' + [file_changed, change_proc, metainfo_changed].inspect }
        log(:debug) { node.full_path + ': ' + node.meta_info.inspect }
        node.node_info[:node_changed] = file_changed || metainfo_changed || change_proc
      end
      node.node_info[:node_changed]
    end

    # Writes data to the file +dest+ using the options in the hash +opts+. This method has to be
    # used by any plugin that needs to write a file to the output directory!
    #
    # Valid keys for the +opts+ hash are:
    #
    # * <tt>:src</tt>: The data is in the file specified by this key and the file
    #   should just be copied to the destination.
    # * <tt>:data</tt>: Contains the actual data which needs to be written to the destination.
    #
    # If both keys are specified, <tt>:data</tt> is discarded.
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
    def render_website
      log(:info) { "Starting rendering of website <#{param('websiteDir', 'Core/Configuration')}>..." }
      log(:info) { "Using webgen data directory at <#{Webgen.data_dir}>" }
      log(:debug) { "Available plugins: " + @plugin_manager.plugin_infos.keys.sort.join(', ') }

      tree = build_tree
      unless tree.nil?
        #@plugin_manager['Misc/TreeWalker'].execute( tree ) TODO activate again!
        write_tree( tree )
      end
      dispatch_msg( :after_website_rendered )

      log(:info) { "Rendering of website <#{param('websiteDir', 'Core/Configuration')}> finished" }
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
          node.meta_info = node.meta_info.merge( data )
        else
          log(:info) { "Creating virtual node for path <#{path}>..." }
          handler = (path =~ /\/$/ ? @plugin_manager['File/DirectoryHandler'] : @plugin_manager['File/VirtualFileHandler'])
          node = create_node( path, root, handler ) do |parent, file_info, handler|
            file_info.meta_info.update( data )
            handler.create_node( parent, file_info )
          end
        end
        check_node( node )
      end
    end

    # Reads all files from the source directory and constructs the node tree which is returned.
    def build_tree
      return nil unless File.directory?( param( 'srcDir', 'Core/Configuration' ) )

      all_files = find_all_files()

      files_for_handlers = find_files_for_handlers()

      root_node = create_root_node()

      used_files = Set.new
      files_for_handlers.sort {|a,b| a[0] <=> b[0]}.each do |rank, handler, files|
        log(:debug) { "Creating nodes for #{handler.plugin_name} with rank #{rank}" }
        common = all_files & files
        used_files += common
        diff = files - common
        log(:info) { "Not using these files for #{handler.plugin_name} as they do not exist or are excluded: #{diff.inspect}" } if diff.length > 0
        common.sort {|a,b| a.length <=> b.length }.each  do |file|
          log(:info) { "Creating node(s) for file <#{file}>..." }
          create_node( file.sub( /^#{Regexp.escape(root_node.node_info[:src])}/, '' ), root_node, handler )
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
      @plugin_manager['Core/CacheManager'].add( [:files_owned], node.full_path ) unless node.node_info[:no_output_file]
      dispatch_msg( :after_node_written, node, changed )
    end

    # Creates a set of all files in the source directory, removing all files which should be ignored.
    def find_all_files
      all_files = files_for_pattern( '**/{**,**/}' ).to_set
      param( 'ignorePaths' ).each {|pattern| all_files.subtract( files_for_pattern( pattern ) ) }
      all_files
    end

    # Finds the files for each registered handler plugin and stores them in a Hash with the plugin
    # as key.
    def find_files_for_handlers
      files_for_handlers = []
      @plugin_manager.plugin_infos.keys.each do |name|
        files_for_plugin = Set.new
        if name =~ /^File\// && (plugin = @plugin_manager[name])
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
      files = Dir.glob( File.join( param( 'srcDir', 'Core/Configuration' ), pattern ), File::FNM_CASEFOLD ).to_set
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

      file_info = FileInfo.new( root_path )
      file_info.meta_info.update( meta_info_for( root_handler.plugin_name, file_info, '/' ) )
      root = root_handler.create_node( nil, file_info )
      root.path = File.join( param( 'outDir', 'Core/Configuration' ), '/' )
      root.cn.sub!( /.*/, '' )
      root.node_info[:src] = root_path

      root
    end

  end

end
