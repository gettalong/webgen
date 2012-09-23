# -*- encoding: utf-8 -*-

require 'webgen/extension_manager'
require 'stringio'
require 'set'
require 'benchmark'

module Webgen

  # Namespace for all path handlers.
  #
  # == About
  #
  # A path handler is a webgen extension that uses source Path objects to create Node objects and
  # that provides methods for rendering these nodes. The nodes are stored in a hierarchy, the root
  # of which is a Tree object. Path handlers can do simple things, like copying a path from the
  # source to the destination, or a complex things, like generating a whole set of nodes from one
  # input path (e.g. generating a whole image gallery)!
  #
  # The paths that are handled by a path handler are specified via path patterns (see below). The
  # #create_nodes method of a path handler is called for each source path that matches a specified
  # path pattern. And when it is time to write out a node, the #content method on the associated
  # path handler is called to retrieve the rendered content of the node.
  #
  # Also note that any method invoked on a Node object that is not defined in the Node class itself
  # is forwarded to the associated path handler, adding the node as first parameter to the parameter
  # list.
  #
  # === Tree creation
  #
  # The method #populate_tree is used for creating the initial node tree, the internal
  # representation of all paths. It is only the initial tree because it is possible that additional,
  # secondary nodes are created during the rendering phase by using the #create_secondary_nodes
  # method.
  #
  # Tree creation works like this:
  #
  # 1. All path handlers on the invocation list are used in turn. The order is important; it allows
  #    avoiding unnecessary write phases and it makes sure that, for example, directory nodes are
  #    created before their file nodes.
  #
  # 2. When a path handler is used for creating nodes, all source paths (retrieved by using
  #    Webgen::Source#paths method) that match one of the associated patterns are used.
  #
  # 3. The meta information of a used source path is then updated with the meta information from the
  #    'path_handler.default_meta_info' configuration option key.
  #
  #    After that the source path is given to the #parse_meta_info! method of the path handler so
  #    that meta information of the path can be updated with meta information stored in the content
  #    of the path itself.
  #
  #    Then the meta information 'versions' is used to determine if multiple version of the path
  #    should be used for creating nodes and each path version is then given to the #create_nodes
  #    method of the path handler so that it can create one or more nodes.
  #
  # 4. Nodes returned by the #creates_nodes of a path handler are assumed to have the Node#node_info
  #    keys :path and :path_handler and the meta info key 'modified_at' correctly set (this is
  #    automatically done if the Webgen::PathHandler::Base#create_node method is used).
  #
  # === Path Patterns and Invocation order
  #
  # Path patterns define which paths are handled by a specific path handler. These patterns are
  # specified when a path handler is registered using #register method. The patterns need to have a
  # format that Dir.glob can handle.
  #
  # In addition to specifying the patterns a path handler uses, one can also specify the place in
  # the invocation list which the path handler should use. The invocation list is used from the
  # front to the back when the Tree is created.
  #
  # == Implementing a path handler
  #
  # A path handler must take the website as the only parameter on initialization and needs to define
  # the following methods:
  #
  # [parse_meta_info!(path)]
  #
  #   Update +path.meta_info+ with meta information found in the content of the path. The return
  #   values of this method are given to the #create_nodes method as additional parameters!
  #
  #   This allows one to use a single pass for reading the meta information and the normal content
  #   of the path.
  #
  # [#create_nodes(path, ...)]
  #
  #   Create one or more nodes from the path and return them. If #parse_meta_info! returns one or
  #   more values, these values are provided as additional parameters to this method.
  #
  #   It is a good idead to use the helper method Webgen::PathHandler::Base#create_node for actually
  #   creating a node.
  #
  # [#content(node)]
  #
  #   Return the content of the given node. This method is only called for nodes that have been
  #   created by the path handler.
  #
  # Also note that a path handler does not need to reside under the Webgen::PathHandler namespace
  # but all built-in ones do so that auto-loading of the path handlers works.
  #
  # The Webgen::PathHandler::Base module provides default implementations of the needed methods
  # (except for #create_nodes) and should be used by all path handlers! If a path handler processes
  # paths in Webgen Page Format, it should probably also use Webgen::PathHandler::PageUtils.
  #
  # Information that is used by a path handler only for processing purposes should be stored in the
  # #node_info hash of a node as the #meta_info hash is reserved for user provided node meta
  # information.
  #
  # Following is a simple path handler class example which copies paths from the source to the
  # destination and modifies the extension in the process:
  #
  #   class SimpleCopy
  #
  #     include Webgen::PathHandler::Base
  #
  #     def create_nodes(path)
  #       path.ext += '.copied'
  #       create_node(path)
  #     end
  #
  #     def content(node)
  #       node.node_info[:path]
  #     end
  #
  #   end
  #
  #   website.ext.path_handler.register(SimpleCopy, patterns: ['**/*.jpg', '**/*.png'])
  #
  class PathHandler

    include Webgen::ExtensionManager

    # The destination node if one is currently written (only during the invocation of #write_tree)
    # or +nil+ otherwise.
    attr_reader :current_dest_node

    # Create a new path handler object for the given website.
    def initialize(website)
      super()
      @website = website
      @current_dest_node = nil
      @invocation_order = []
      @instances = {}
      @secondary_nodes = {}

      @website.blackboard.add_listener(:website_generated, self) do
        @website.cache[:path_handler_secondary_nodes] = @secondary_nodes
      end

      created_secondary_paths = {}
      @website.blackboard.add_listener(:create_secondary_nodes, self) do |path, source_alcn|
        (created_secondary_paths[source_alcn] ||= Set.new) << path if source_alcn
      end
      @website.blackboard.add_listener(:after_node_written, self) do |node|
        @secondary_nodes.select do |path, data|
          data.first == node.alcn && !created_secondary_paths[node.alcn].include?(path)
        end.each do |path, data|
          delete_secondary_nodes(path)
        end
        created_secondary_paths = {}
      end
    end

    # Register a path handler.
    #
    # The parameter +klass+ has to contain the name of the path handler class or the class object
    # itself. If the class is located under this namespace, only the class name without the
    # hierarchy part is needed, otherwise the full class name including parent module/class names is
    # needed.
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


    # Populate the website tree with nodes.
    #
    # Can only be called once because the tree can only be populated once!
    def populate_tree
      raise Webgen::NodeCreationError.new("Can't populate tree twice", self.class.name) if @website.tree.root

      create_nodes

      used_paths = @website.tree.node_access[:alcn].values.map {|n| n.node_info[:path]}
      unused_paths = @website.ext.source.paths.values - used_paths
      @website.logger.vinfo do
        "The following source paths have not been used: #{unused_paths.join(', ')}"
      end if unused_paths.length > 0

      (@website.cache[:path_handler_secondary_nodes] || {}).each do |path, (source_alcn, handler, content, node_alcns)|
        next if @secondary_nodes.has_key?(path) || !@website.tree[source_alcn]
        create_secondary_nodes(path, content, handler, source_alcn)
      end
      @website.blackboard.dispatch_msg(:after_tree_populated)
    end

    # Write all changed nodes of the website tree to their respective destination using the
    # Destination object at +website.ext.destination+.
    #
    # Returns the number of passes needed for correctly writing out all paths.
    def write_tree
      passes = 0

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
        passes += 1 if at_least_one_node_written
      end while at_least_one_node_written

      @website.blackboard.dispatch_msg(:website_generated)
      passes
    end

    # Write the given node to the destination.
    def write_node(node)
      @current_dest_node = node
      @website.logger.info do
        "[#{(@website.ext.destination.exists?(node.dest_path) ? 'update' : 'create')}] <#{node.dest_path}>"
      end
      time = Benchmark.measure { @website.ext.destination.write(node.dest_path, node.content) }
      @website.logger.debug do
        "[timing] <#{node.dest_path}> rendered in " << ('%2.2f' % time.real) << ' seconds'
      end
    ensure
      @current_dest_node = nil
    end
    private :write_node

    # Use the registered path handlers to create nodes which are all returned.
    #
    # If +paths+ is nil, all source paths are used. Otherwise +paths+ needs to be an array of path
    # names.
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

    # Create nodes for the given +path+ (a Path object which must not be a source path).
    #
    # The content of the path also needs to be specified. Note that if an IO block is associated
    # with the path, it is discarded!
    #
    # If the parameter +handler+ is present, nodes from the given path are only created with the
    # specified handler.
    #
    # If the secondary nodes are created during the rendering phase (and not during node creation,
    # ie. in a #create_nodes method of a path handler), the +source_alcn+ has to be set to the node
    # alcn from which these nodes are created!
    def create_secondary_nodes(path, content, handler = nil, source_alcn = nil)
      @website.blackboard.dispatch_msg(:create_secondary_nodes, path, source_alcn)

      sn = @secondary_nodes[path]
      if sn && sn[0] == source_alcn && sn[1] == handler && sn[2] == content
        nodes = sn[3].map {|a| @website.tree[a]}.compact
        if sn[3].length == nodes.length
          return nodes
        elsif nodes.length > 0
          raise "webgen bug - please report!"
        else
          @secondary_nodes.delete(path)
        end
      elsif sn
        raise Webgen::NodeCreationError.new("Duplicate secondary path name <#{path}>", self.class.name, path)
      end

      path['modified_at'] ||= @website.tree[source_alcn]['modified_at'] if source_alcn
      path.set_io(&nil)
      @secondary_nodes[path.dup] = data = [source_alcn, handler, content] if source_alcn

      path.set_io { StringIO.new(content) }
      nodes = if handler
                create_nodes_with_path_handler(path, handler)
              else
                nodes = create_nodes([path])
              end
      data << nodes.map {|n| n.alcn} if source_alcn

      nodes
    end

    # Delete all secondary nodes created from the given path.
    def delete_secondary_nodes(path)
      data = @secondary_nodes.delete(path)
      data[3].each {|alcn| @website.tree.delete_node(@website.tree[alcn])}
    end
    private :delete_secondary_nodes

    # Return the paths which are handled by the path handler +name+.
    #
    # If the parameter +paths+ is not nil, only handled paths that also appear in this array are
    # returned.
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
      path.meta_info.update(Marshal.load(Marshal.dump(mi)))
    end
    private :apply_default_meta_info

  end

end
