module FileHandlers

  # TODO(redo): The default handler which is the super class of all file handlers. It defines methods that
  # should be used by the subclasses to specify which files should be handled. There are two types
  # of path patterns: constant ones defined using the class methods and dynamic ones defined using
  # the instance methods. The dynamic path patterns should be defined during the initialization!
  #
  # During a webgen run the FileHandler retrieves all plugins which derive from the DefaultHandler
  # and uses the constant and dynamic path patterns defined for each file handler plugin for finding
  # the handled files.
  #
  # TODO: how path patterns/default meta info are defined in plugin.yaml
  class DefaultHandler

    EXTENSION_PATH_PATTERN = "**/*.%s"
    DEFAULT_RANK = 100

    # Specify the path pattern which should be handled by the class. The +rank+ is used for sorting
    # the patterns so that the creation order of nodes can be influenced. If a file is matched by
    # more than one path pattern defined by a single file handler plugin, it is only used once for
    # the first pattern.
    def register_path_pattern( path, rank = DEFAULT_RANK )
      (@path_patterns ||= []) << [rank, path]
    end
    protected :register_path_pattern

    # Specify the files handled by the class via the extension. The parameter +ext+ should be the
    # pure extension without the dot. Also see #register_path_pattern !
    def register_extension( ext, rank = DEFAULT_RANK )
      register_path_pattern( EXTENSION_PATH_PATTERN % [ext], rank )
    end
    protected :register_extension

    # Returns all (i.e. static and dynamic) path patterns defined for the file handler.
    def path_patterns
      if file_section = @plugin_manager.plugin_infos.get( @plugin_name, 'file' )
        patterns = file_section['patterns'] || []
        patterns += (file_section['extensions'] || []).collect {|rank,ext| [rank, EXTENSION_PATH_PATTERN % [ext]]}
      end
      (patterns || []) + (@path_patterns || [])
    end

    # TODO(adept for file_struct) Asks the plugin to create a node for the given +path+ and the +parent+, using +meta_info+ as
    # default meta data for the node. Should return the node for the path (the newly created node
    # or, if a node with the path already exists, the existing one) or +nil+ if the node could not
    # be created.
    #
    # Has to be overridden by the subclass!!!
    def create_node( file_struct, parent, meta_info )
      raise NotImplementedError
    end

    # TODO(adept for return value) Asks the plugin to write out the node.
    def write_info( node )
      nil
    end

    # (TODO:adept)Returns the node with the same canonical name but in language +lang+ or, if no such node exists,
    # an unlocalized version of the node. If no such node is found either, +nil+ is returned.
    def node_for_lang( node, lang )
      node.parent.find {|o| o.cn == node.cn && o['lang'] == lang} || node.parent.find {|o| o.cn == self.cn && o['lang'].nil?}
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

end
