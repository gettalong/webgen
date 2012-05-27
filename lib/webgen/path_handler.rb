# -*- encoding: utf-8 -*-

require 'webgen/common'
require 'stringio'
require 'set'
require 'benchmark'

module Webgen

  # Namespace for all path handlers.
  #
  # == Implementing a path handler
  #
  # A path handler is a webgen extension that uses source Path objects to create Node objects and
  # that provides methods for rendering these nodes. The nodes are stored in a hierarchy, the root
  # of which is a Tree object. Path handler can do simple things, like copying a path from the
  # source to the destination, or a complex things, like generating a whole set of nodes from one
  # input path (e.g. generating a whole image gallery)!
  #
  # The paths that are handled by a path handler are specified via path patterns (see below). The
  # #create_nodes method of a path handler is called for each source path that matches a specified
  # path pattern. And when it is time to write out a node, the #content method on the associated
  # path handler is called to retrieve the rendered content of the node.
  #
  # TODO: from here onwards
  #
  # A path handler must not take any parameters on initialization and when this module is not mixed
  # in, the methods #create_node and #content need to be defined. Also, a source handler does not
  # need to reside under the Webgen::SourceHandler namespace but all shipped ones do.
  #
  # This base class provides useful default implementations of methods that are used by nearly all
  # source handler classes:
  # * #create_node
  # * #output_path
  # * #node_exists?
  #
  # It also provides other utility methods:
  # * #page_from_path
  # * #content
  # * #parent_node
  #
  # == Nodes Created for Paths
  #
  # The main functions of a source handler class are to create one or more nodes for a source path
  # and to provide the content of these nodes. To achieve this, certain information needs to be set
  # on a created node. If you use the +create_node+ method provided by this base class, you don't
  # need to set them explicitly because this is done by the method:
  #
  # [<tt>node_info[:processor]</tt>] Has to be set to the class name of the source handler. This is
  #                                  used by the Node class: all unknown method calls are forwarded
  #                                  to the node processor.
  # [<tt>node_info[:src]</tt>] Has to be set to the string version of the path that lead to the
  #                            creation of the node.
  # [<tt>node_info[:creation_path]</tt>] Has to be set to the string version of the path that is
  #                                      used to create the path.
  # [<tt>meta_info['no_output']</tt>] Has to be set to +true+ on nodes that are used during a
  #                                   webgen run but do not produce an output file.
  # [<tt>meta_info['modified_at']</tt>] Has to be set to the current time if not already set
  #                                     correctly (ie. if not a Time object).
  #
  # If <tt>meta_info['draft']</tt> is set on a path, then no node should be created in +create_node+
  # and +nil+ has to be returned.
  #
  # Note: The difference between +:src+ and +:creation_path+ is that a creation path
  # need not have an existing source path representation. For example, fragments created from a page
  # source path have a different +:creation_path+ which includes the fragment part.
  #
  # Additional information that is used only for processing purposes should be stored in the
  # #node_info hash of a node as the #meta_info hash is reserved for real node meta information and
  # should not be changed once the node is created.
  #
  # == Output Path Names
  #
  # The method for creating an output path name for a source path is stored in the meta information
  # +output_path+. If you don't use the provided method +output_path+, have a look at its
  # implementation to see how to an output path gets created. Individual output path creation
  # methods are stored as methods in the OutputPathHelpers module.
  #
  # == Path Patterns and Invocation order
  #
  # Path patterns define which paths are handled by a specific source handler. These patterns are
  # specified in the <tt>sourcehandler.patterns</tt> configuration hash as a mapping from the source
  # handler class name to an array of path patterns. The patterns need to have a format that
  # <tt>Dir.glob</tt> can handle. You can use the configuration helper +patterns+ to set this (is
  # shown in the example below).
  #
  # Specifying a path pattern does not mean that webgen uses the source handler. One also needs to
  # provide an entry in the configuration value <tt>sourcehandler.invoke</tt>. This is a hash that
  # maps the invocation rank (a number) to an array of source handler class names. The lower the
  # invocation rank the earlier the specified source handlers are used.
  #
  # The default invocation ranks are:
  # [1] Early. Normally there is no need to use this rank.
  # [5] Standard. This is the rank the normal source handler should use.
  # [9] Late. This rank should be used by source handlers that operate on/use already created nodes
  #     and need to ensure that these nodes are available.
  #
  # == Default Meta Information
  #
  # Each path handler can define default meta information that gets automatically set on the source
  # paths that are passed to the #create_node method.
  #
  # The default meta information is specified in the <tt>sourcehandler.default_meta_info</tt>
  # configuration hash as a mapping from the source handler class name to the meta information
  # hash.
  #
  # == Sample Path Handler
  #
  # Following is a simple path handler class example which copies paths from the source to the
  # destination and modifies the extension:
  #
  #   class SimpleCopy
  #
  #     include Webgen::SourceHandler::Base
  #     include Webgen::WebsiteAccess
  #
  #     def create_nodes(path)
  #       path.ext += '.copied'
  #       super(path)
  #     end
  #
  #     def content(node)
  #       website.blackboard.invoke(:source_paths)[node.node_info[:src]].io
  #     end
  #
  #   end
  #
  #   website.ext.path_handler.register(SimpleCopy, patterns: ['**/*.jpg', '**/*.png'])
  #
  class PathHandler

    include Webgen::Common::ExtensionManager

    # Create a new path handler object for the given website.
    def initialize(website)
      super()
      @website = website
      @invocation_order = []
      @instances = {}
      @secondary_nodes = {}

      @website.blackboard.add_listener(:website_generated, self) do
        @website.cache[:path_handler_secondary_nodes] = @secondary_nodes
      end
    end

    # Register a path handler. The parameter +klass+ has to contain the name of the path handler
    # class. If the class is located under this namespace, only the class name without the hierarchy
    # part is needed, otherwise the full class name including parent module/class names is needed.
    #
    # === Options:
    #
    # [:name] The name for the path handler. If not set, it defaults to the snake-case version of
    #         the class name (without the hierarchy part). It should only contain letters.
    #
    # [:patterns] A list of path patterns for which the path handler should be used. If not
    #             specified, defaults to an empty list.
    #
    # [:insert_at] Specifies the position in the invocation list. If not specified or if :end is
    #              specified, the handler is added to the end of the list. If :front is specified,
    #              it is added to the beginning of the list. Otherwise the value is expected to be a
    #              position number and the path handler is added at the specified position in the
    #              list.
    #
    # [:author] The author of the path handler class.
    #
    # [:summary] A short description of the path handler class.
    #
    # === Examples:
    #
    #   path_handler.register('Template')     # registers Webgen::PathHandler::Template
    #
    #   path_handler.register('::Template')   # registers Template !!!
    #
    #   path_handler.register('MyModule::Doit', name: 'template', patterns: ['**/*.template'])
    #
    def register(klass, options={}, &block)
      name = do_register(klass, options, false, &block)
      ext_data(name).patterns = options[:patterns] || []
      pos = if options[:insert_at].nil? || options[:insert_at] == :end
              -1
            elsif options[:insert_at] == :front
              0
            else
              options[:insert_at].to_i
            end
      @invocation_order.delete(name)
      @invocation_order.insert(pos, name)
    end

    # Return the instance of the path handler class with the given name.
    def instance(handler)
      @instances[handler] ||= extension(handler).new(@website)
    end

    # Main webgen task: generate the website.
    #
    # Returns +true+ if the website has been generated.
    def generate_website
      successful = true
      @website.logger.info { "Generating website..." }
      time = Benchmark.measure do
        populate_tree
        @website.blackboard.dispatch_msg(:after_tree_populated)
        if @website.tree.root && !@website.tree.root['passive']
          write_tree
          @website.blackboard.dispatch_msg(:website_generated)
        else
          successful = false
          @website.logger.info { 'No source paths found - maybe not a webgen website?' }
        end
      end
      @website.logger.info { "... done in " << ('%2.2f' % time.real) << ' seconds' }
      successful
    end

    # Populate the website tree with nodes. Can only be called once because the tree can only be
    # populated once!
    def populate_tree
      raise Webgen::NodeCreationError.new("Can't populate tree twice", self.class.name) if @website.tree.root

      create_nodes

      used_paths = @website.tree.node_access[:alcn].values.map {|n| n.node_info[:path]}
      unused_paths = @website.ext.source.paths.values - used_paths
      @website.logger.debug do
        "The following source paths have not been used: #{unused_paths.join(', ')}"
      end

      (@website.cache[:path_handler_secondary_nodes] || {}).each do |path, (source_alcn, handler, content)|
        next if @secondary_nodes.has_key?(path) || !@website.tree[source_alcn]
        create_secondary_nodes(path, content, handler, source_alcn)
      end
    end

    # Write all changed nodes of the website tree to the respective destination.
    def write_tree
      begin
        at_least_one_node_written = false
        @website.cache.reset_volatile_cache
        @website.tree.node_access[:alcn].sort.each do |name, node|
          begin
            next if node == @website.tree.dummy_root ||
              (node['passive'] && !@website.ext.item_tracker.node_referenced?(node)) ||
              (@website.ext.destination.exists?(node.dest_path) && !@website.ext.item_tracker.node_changed?(node))

            if !node['no_output']
              write_node(node)
              at_least_one_node_written = true
            end
            @website.blackboard.dispatch_msg(:after_node_written, node)
          rescue Webgen::Error => e
            e.path = node.alcn if e.path.to_s.empty?
            raise
          rescue Exception => e
            raise Webgen::RenderError.new(e, nil, node)
          end
        end
        @website.blackboard.dispatch_msg(:after_all_nodes_written)
      end while at_least_one_node_written
    end

    # Write the given node to the destination.
    def write_node(node)
      @website.logger.info do
        "[#{(@website.ext.destination.exists?(node.dest_path) ? 'update' : 'create')}] <#{node.dest_path}>"
      end
      time = Benchmark.measure do
        delete_secondary_nodes(node.alcn)
        @website.ext.destination.write(node.dest_path, node.content)
      end
      @website.logger.debug do
        "[timing] <#{node.dest_path}> rendered in " << ('%2.2f' % time.real) << ' seconds'
      end
    end
    private :write_node

    # Use the registered path handlers to create nodes which are all returned. If +paths+ is nil,
    # all source paths are used. Otherwise +paths+ needs to be an array of path names.
    def create_nodes(paths = nil)
      nodes = Set.new
      @invocation_order.each do |name|
        paths_for_handler(name, paths).sort {|a,b| a.path.length <=> b.path.length}.each do |path|
          nodes += create_nodes_with_path_handler(path, name)
        end
      end
      nodes
    end
    private :create_nodes

    # Create nodes for the given +path+ (a Path object which must not be a source path). The content
    # of the path also needs to be specified. Note that if an IO block is associated with the path,
    # it is discarded!
    #
    # If the parameter +handler+ is present, nodes from the given path are only created with the
    # handler.
    #
    # If the secondary nodes are created during the rendering phase, the +source_alcn+ has to be set
    # to the node alcn from which these nodes are created!
    def create_secondary_nodes(path, content, handler = nil, source_alcn = nil)
      path.set_io { StringIO.new(content) }
      if @secondary_nodes.has_key?(path.path)
        raise Webgen::NodeCreationError.new("Duplicate secondary path name <#{path.path}>", self.class.name, path)
      end
      @secondary_nodes[path.path] = [source_alcn, handler, content] if source_alcn

      nodes = if handler
                create_nodes_with_path_handler(path, handler)
              else
                nodes = create_nodes([path])
              end
      nodes.each {|n| n.node_info[:source_alcn] = source_alcn} if source_alcn
      nodes
    end

    # Recursively delete all secondary nodes created from the given alcn.
    def delete_secondary_nodes(alcn)
      @secondary_nodes.delete_if {|path, (source_alcn, content)| source_alcn == alcn}
      @website.tree.node_access[:alcn].each do |_, node|
        if node.node_info[:source_alcn] == alcn
          delete_secondary_nodes(node.alcn)
          @website.tree.delete_node(node)
        end
      end
    end
    private :delete_secondary_nodes

    # Return the paths which are handled by the path handler +name+. If the parameter +paths+ is not
    # nil, only handled paths that also appear in this array are returned.
    def paths_for_handler(name, paths = nil)
      patterns = ext_data(name).patterns
      if @website.config.option?("path_handler.#{name}.patterns")
        patterns += @website.config["path_handler.#{name}.patterns"]
      end
      return [] if patterns.nil? || patterns.empty?

      options = (@website.config['path_handler.patterns.case_sensitive'] ? 0 : File::FNM_CASEFOLD) |
        (@website.config['path_handler.patterns.match_leading_dot'] ? File::FNM_DOTMATCH : 0) |
        File::FNM_PATHNAME

      (paths.nil? ? @website.ext.source.paths.values : paths).compact.select do |path|
        patterns.any? {|pat| Webgen::Path.matches_pattern?(path, pat, options)}
      end
    end
    private :paths_for_handler

    # Prepare everything to create nodes from the path using the given handler. After the nodes are
    # created, it is checked if they have all needed properties.
    #
    # Returns an array with all created nodes.
    def create_nodes_with_path_handler(path, handler) #:yields: path
      path = path.dup
      apply_default_meta_info(path, handler)
      @website.blackboard.dispatch_msg(:before_node_created, path)

      *data = instance(handler).parse_meta_info!(path)
      nodes = []

      versions = path.meta_info.delete('versions') || {'default' => {'version' => path.meta_info['version']}}
      versions.each do |name, mi|
        vpath = path.dup
        mi['version'] ||= name
        raise Webgen::NodeCreationError.new("Meta info 'version' must not be empty") if mi['version'].empty?
        vpath.meta_info.merge!(mi)
        next if vpath.meta_info['handler'] && vpath.meta_info['handler'] != handler
        @website.logger.debug do
          "Creating node version '#{mi['version']}' from path <#{path}> with #{handler} handler"
        end
        nodes << instance(handler).create_nodes(vpath, *data)
      end

      nodes.flatten.compact.each do |node|
        node.node_info[:path_handler] = instance(handler)
        @website.blackboard.dispatch_msg(:after_node_created, node)
      end
    rescue Webgen::Error => e
      e.path = path.to_s if e.path.to_s.empty?
      e.location = instance(handler).class.name unless e.location
      raise
    rescue Exception => e
      raise Webgen::NodeCreationError.new(e, instance(handler).class.name, path)
    end
    private :create_nodes_with_path_handler

    # Apply the default meta info (general and handler specific) to the path.
    def apply_default_meta_info(path, handler)
      mi = @website.config['path_handler.default_meta_info'][:all].dup
      mi.merge!(@website.config['path_handler.default_meta_info'][handler.to_s] || {})
      mi.merge!(path.meta_info)
      path.meta_info.update(mi)
    end
    private :apply_default_meta_info

  end

end
