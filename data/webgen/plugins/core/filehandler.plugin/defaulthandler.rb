module FileHandlers

  # This class serves as base class for all file handlers. Have a look a the example below to see
  # how a basic file handler looks like.
  #
  # = File Handlers
  #
  # A file handler is a plugin that processes files in the source directory to produce output
  # files. This can range from simply copying a file from the source to the output directory to
  # generating a whole set of files from one input file!
  #
  # The files that are handled by file handler are specified via path patterns (see below). During a
  # webgen run the Core::FileHandler plugin calls the #create_node method for each file in the source
  # directory that matches a specified path pattern. And when it is time to write out the node, the
  # Core::FileHandler plugin calls the #write_info method to retrieve the information about how to
  # write out the node.
  #
  # Each file handler plugin has to reside under the <tt>File/</tt> namespace!
  #
  # This base class provides some useful default implementations of methods that are used throughout
  # webgen, namely
  # * #link_from
  # * #node_for_lang.
  #
  # It also provides utility methods for file handler plugins:
  # * #node_exist?
  #
  # = Nodes created for files
  #
  # The main functions of a file handler plugin are to create one or more nodes for a source file
  # and to provide information on how to write out these nodes. To achieve this, certain information
  # needs to be set on a node:
  #
  # :<tt>node_info[:processor]</tt>:: Has to be set to the file handler plugin instance. This is
  #                                   used by the Node class: all unknown method calls are forwarded
  #                                   to the node processor.
  # :<tt>node_info[:src]</tt>:: Should be set to the source file from which the node is created if
  #                             such a source file exists.
  #
  # Additional information that is used only for processing purposes should be stored in the
  # #node_info hash of a node as the #meta_info hash is reserved for real node meta information.
  #
  # = Path Patterns and Rank
  #
  # Path patterns define which files are handled by a specific file handler. These patterns can
  # either be defined in the plugin information file or dynamcially and need to have a format that
  # <tt>Dir.glob</tt> can handle. A rank is associated with each path pattern that defines in which
  # order the path patterns are searched for (and therefore ultimately in which order nodes are
  # created). Path patterns with a lower rank are first search for.
  #
  # The section +file+ for file handler plugin in a <tt>plugin.yaml</tt> is used to define
  # everything related to file handling. There are two keys in this section used for specifying path
  # patterns for a file handler:
  #
  # :+patterns+::   The value of this key has to be an array of path patterns.
  # :+extensions+:: The value of this key has to be an array of extensions. An extension is, for
  #                 example, +page+ (no leading dot). This extension gets combined with the
  #                 EXTENSION_PATH_PATTERN constant to form a valid path pattern.
  #
  # You can also specify a rank with a pattern or an extension: just use an array containing the
  # rank and the pattern/extension instead of just the pattern/extension.
  #
  # The dynamically defined path patterns should be added during the initialization phase
  # in the +init_plugin+ method by using the approriate methods!
  #
  # = Default Meta Information
  #
  # Each file handler can define default meta information that gets later passed to the #create_node
  # method. This default meta information can later be overridden using the param
  # Core::FileHandler:defaultMetaInfo.
  #
  # The default meta information is specified in the +file+ section of a file handler plugin in the
  # <tt>plugin.yaml</tt> using the key +defaultMetaInfo+.
  #
  # = Sample File Handler Plugin
  #
  # Following is a simple file handler example which just copies files from the source to the output
  # directory.
  #
  # The <tt>plugin.yaml</tt> file:
  #
  #   File/CopyHandler:
  #     plugin:
  #       file: copyhandler.rb
  #       load_deps: File/DefaultHandler
  #       run_deps: Core/FileHandler
  #       class: CopyHandler
  #     params:
  #       paths:
  #         default: [**/*.css, **/*.js, **/*.jpg, **/*.png, **/*.gif]
  #         desc: The path patterns which match the files that should get copied by this handler.
  #
  # The <tt>copyhandler.rb</tt> file:
  #
  #   class CopyHandler < DefaultHandler
  #
  #     def init_plugin
  #       param( 'paths' ).each {|path| register_path_pattern( path ) }
  #     end
  #
  #     def create_node( file_struct, parent, meta_info )
  #       name = File.basename( file_struct.filename )
  #
  #       unless node = node_exist?( parent, name )
  #         node = Node.new( parent, name, file_struct.cn )
  #         node.meta_info.update( meta_info )
  #         node.node_info[:src] = file_struct.filename
  #         node.node_info[:processor] = self
  #       end
  #       node
  #     end
  #
  #     def write_info( node )
  #       {:src => node.node_info[:src] }
  #     end
  #
  #   end
  #
  class DefaultHandler

    # The string used to define a pattern from an extension.
    EXTENSION_PATH_PATTERN = "**/*.%s"

    # The default rank for a pattern if none specified.
    DEFAULT_RANK = 100


    # Used to specify the path pattern which should be handled by the class. The +rank+ is used for
    # sorting the patterns so that the creation order of nodes can be influenced. If a file is
    # matched by more than one path pattern defined by a single file handler plugin, it is only used
    # once for the first pattern.
    def register_path_pattern( path, rank = DEFAULT_RANK )
      (@path_patterns ||= []) << [rank, path]
    end
    protected :register_path_pattern

    # Used to specify the files handled by the class via the extension. The parameter +ext+ should
    # be the pure extension without the dot. Also see #register_path_pattern !
    def register_extension( ext, rank = DEFAULT_RANK )
      register_path_pattern( EXTENSION_PATH_PATTERN % [ext], rank )
    end
    protected :register_extension

    # Returns all (i.e. static and dynamic) path patterns defined for the file handler.
    def path_patterns
      if file_section = @plugin_manager.plugin_infos.get( @plugin_name, 'file' )
        patterns = (file_section['patterns'] || []).collect do |rank, pattern|
          (pattern.nil? ? [DEFAULT_RANK, rank] : [rank, pattern])
        end
        patterns += (file_section['extensions'] || []).collect do |rank,ext|
          (ext.nil? ? [DEFAULT_RANK, EXTENSION_PATH_PATTERN % [rank]] : [rank, EXTENSION_PATH_PATTERN % [ext]])
        end
      end
      (patterns || []) + (@path_patterns ||= [])
    end

    # Asks the plugin to create a node with the information provided in +file_info+ (see
    # Core::FileHandler::FileInfo) and the +parent+ node. The default meta information for the node
    # can be accessed using <tt>file_info.meta_info</tt> (created using
    # Core::FileHandler#meta_info_for). Should return the node for the path (the newly created node
    # or, if a node with the same output path already exists, the existing one) or +nil+ if the node
    # could not be created.
    #
    # Has to be overridden by the subclass!!!
    def create_node( parent, file_info )
      raise NotImplementedError
    end

    # Should return a hash with information on how to write out the node or +nil+ if the node should
    # not be written. For more information about this hash have a look at
    # Core::FileHandler#write_path.
    #
    # The default implementation returns +nil+.
    def write_info( node )
      nil
    end

    # Returns the node with the same canonical name but in language +lang+ or, if no such node exists,
    # an unlocalized version of the node. If no such node is found either, +nil+ is returned.
    def node_for_lang( node, lang )
      node.parent.find {|o| o.cn == node.cn && o['lang'] == lang} || node.parent.find {|o| o.cn == node.cn && o['lang'].nil?}
    end

    # Returns a HTML link to the +node+ from +ref_node+ or, if +node+ and +ref_node+ are the same
    # and the parameter +linkToCurrentPage+ is +false+, a +span+ element with the link text.
    #
    # You can optionally specify additional attributes for the html element in the +attr+ Hash.
    # Also, the meta information +linkAttrs+ of the given +node+ is used, if available, to set
    # attributes. However, the +attr+ parameter takes precedence over the +linkAttrs+ meta
    # information. If the special value <tt>:link_text</tt> is present in the attributes, it will be
    # used as the link text; otherwise the title of the +node+ will be used. Be aware that all
    # key-value pairs with Symbol keys are removed before the attributes are written. Therefore you
    # always need to specify general attributes with Strings!
    def link_from( node, ref_node, attr = {} )
      attr = node['linkAttrs'].merge( attr ) if node['linkAttrs'].kind_of?( Hash )
      link_text = attr[:link_text] || node['title']
      attr.delete_if {|k,v| k.kind_of?( Symbol )}

      use_link = ( node != ref_node || param( 'linkToCurrentPage' ) )
      attr['href'] = ref_node.route_to( node ) if use_link
      attrs = attr.collect {|name,value| "#{name.to_s}=\"#{value}\"" }.sort.unshift( '' ).join( ' ' )
      ( use_link ? "<a#{attrs}>#{link_text}</a>" : "<span#{attrs}>#{link_text}</span>" )
    end

    # Checks if there is already a node for the given +path+ or +lcn+ (localized canonical name)
    # under +parent_node+ and returns this node or +nil+ otherwise.
    def node_exist?( parent_node, path, lcn, warning = true )
      path = path.chomp( '/' )
      node = parent_node.find {|n| n.path =~ /#{path}\/?/ || n.lcn == lcn }
      log(:warn) { "There is already a node for <#{node.full_path}> handled by #{node.node_info[:processor].plugin_name}" } if node && warning
      node
    end

    # Constructs the output file name for the given +file_info+ object. Then it is checked using the
    # parameter +parent+ if a node with such an output name already exists. If it exists, the
    # language part is forced to be in the output name and the resulting output name is returned.
    #
    # The parameter +style+ (which uses either the meta information +outputNameStyle+ from the
    # paramter +meta_info+ or, if the former is not defined, the plugin parameter +outputNameStyle+)
    # defines how the output name should be built (more information about this in the user
    # documentation).
    def output_name( parent, file_info, style = file_info.meta_info['outputNameStyle'] || param( 'outputNameStyle' ) )
      path = construct_output_name( file_info, style )
      if parent && node_exist?( parent, path, Node.lcn( file_info.basename, file_info.meta_info['lang'] ), false )
        path = construct_output_name( file_info, style, true )
      end
      path
    end

    #######
    private
    #######

    def construct_output_name( file_info, style, use_lang_part = nil )
      use_lang_part = if file_info.meta_info['lang'].nil?       # unlocalized files never get a lang in the filename!
                        false
                      elsif use_lang_part.nil?
                        param( 'defaultLangInOutputName' ) || param( 'lang', 'Core/Configuration' ) != file_info.meta_info['lang']
                      else
                        use_lang_part
                      end
      style.collect do |part|
        case part
        when String
          part
        when :lang
          use_lang_part ? file_info.meta_info['lang'] : ''
        when :ext
          file_info.ext.empty? ? '' : '.' + file_info.ext
        when Symbol
          file_info.send( part )
        when Array
          part.include?( :lang ) && !use_lang_part ? '' : construct_output_name( file_info, part, use_lang_part )
        else
          ''
        end
      end.join( '' )
    end

  end

end
