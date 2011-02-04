# -*- encoding: utf-8 -*-

require 'set'
require 'webgen/common'
require 'webgen/node'

module Webgen

  # Used for finding nodes that match certain criterias.
  #
  # == About this class
  #
  # This extension class is used for finding nodes that match certain criterias when calling the
  # #find method. There are some built-in filters but one can also provide custom filters via
  # #add_filter_module. The found nodes are either returned in a flat list or hierarchical in nested
  # lists. Sorting, limiting the number of returned nodes and using an offset is also possible.
  #
  # == Finder options
  #
  # Following is the list of all finder options. Note that there may also be other 3rd party node
  # filters available!
  #
  # === Non-filter options
  #
  # [limit] Value: an integer. Specifies the maximum number of nodes that should be returned.
  #         Implies <tt>flatten = true</tt>.
  #
  #         Note that fewer nodes may be returned if fewer nodes match the filter criterias.
  #
  # [offset] Value: an integer. Specifies how many nodes from the front of the list should not be
  #          returned. Implies <tt>flatten = true</tt>.
  #
  # [flatten] Value: anything except +nil+ or +false+. A flat list of nodes is returned if this
  #           option is set, otherwise the nodes are returned in their correct hierarchical order
  #           using nested lists: If a node has no sub nodes, only the node itself is used;
  #           otherwise a two element array containing the node and child nodes is used.
  #
  #           Note that any missing nodes in the hierarchy are automatically added so that
  #           traversing the hierarchy is always possible. For example, if we have the tree
  #           <tt>/a/b/c</tt> and only nodes +a+ and +c+ are found, node +b+ is automatically added.
  #
  # [sort] TODO
  #
  # === Filter options
  #
  # [alcn] Value: an alcn pattern or an array of alcn patterns. Nodes that match any of the patterns
  #        are used.
  #
  # [levels] Value; one integer (is used as start and end level) or an array with two integers (the
  #          start and end levels). All nodes whose hierarchy levels are greater than or equal to
  #          the start level and lower than or equal to the end level are used.
  #
  # == Implementing a filter module
  #
  # Implementing a filter module is very easy. Just create a module that contains your filter
  # methods and tell the NodeFinder object about it. A filter method needs to take three arguments:
  # an array of nodes, the reference node and the filter value.
  #
  # Here is a sample filter module which provides the ability to filter nodes based on the meta
  # information key +category+. The +category+ key contains an array with one or more categories.
  # The value for this category filter is one or more strings and the filter returns those nodes
  # that contain at least one specified category.
  #
  #   module CategoryFilter
  #
  #     def filter_on_category(nodes, ref_node, categories)
  #       categories = [categories].flatten # needed in case categories is a string
  #       nodes.select {|n| categories.any? {|c| n['category'].include?(c)}}
  #     end
  #
  #   end
  #
  #   website.ext.node_finder.add_filter_module(CategoryFilter, category: 'filter_on_category')
  #
  class NodeFinder

    # The website instance to which this object belongs.
    attr_accessor :website

    def initialize # :nodoc:
      super
      @mapping = {'alcn' => :filter_alcn, 'levels' => :filter_levels}
    end

    # Add a module with filter methods. The parameter +mapping+ needs to be a hash associating
    # unique names with the methods of the given module that can be used as finder methods.
    #
    # === Examples:
    #
    #   node_finder.add_filter_module(MyModule, blog: 'filter_on_blog')
    #
    def add_filter_module(mod, mapping)
      public_methods = mod.public_instance_methods.map {|c| c.to_s}
      mapping.each do |name, method|
        if !public_methods.include?(method.to_s)
          raise ArgumentError, "Finder method '#{method}' not found in module #{mod}"
        end
        @mapping[name.to_s] = method
      end
      extend(mod)
    end

    # Return all nodes that match certain criterias. The parameter +opts_or_name+ can either be a
    # hash with finder options or the name of a finder option set defined using the configuration
    # option <tt>node_finder.options_sets</tt>. The node +ref_node+ is used as reference node.
    def find(opts_or_name, ref_node)
      opts, name = if Hash === opts_or_name
                     [opts_or_name.dup, opts_or_name['name']]
                   elsif website.config['node_finder.option_sets'].has_key?(opts_or_name)
                     [website.config['node_finder.option_sets'][opts_or_name].dup, opts_or_name]
                   else
                     raise ArgumentError, "Invalid argument supplied, expected Hash or name of search definition, not #{opts_or_name}"
                   end
      raise ArgumentError, "Each node finder option set needs a name" if name.to_s.empty?

      limit = opts.delete('limit')
      offset = opts.delete('offset')
      flatten = opts.delete('flatten')
      sort = opts.delete('sort')

      nodes = website.tree.node_access[:alcn].values
      opts.keys.each do |filter|
        filter = filter.to_s
        if @mapping.has_key?(filter)
          nodes = send(@mapping[filter], nodes, ref_node, opts[filter])
        else
          website.logger.warn { "Ignorning unknown filter '#{filter}' for node finder option set '#{name}'" }
        end
      end

      #TODO: result.sort!(opts[:sort]) if result
      #sort needs to be done before limit/offset if flatten, else AFTER hierarchy is built

      if limit || offset
        nodes = nodes[(offset.to_s.to_i)..(limit ? offset.to_s.to_i + limit.to_s.to_i - 1 : -1)]
        flatten = true
      end

      if !flatten
        result = {}
        min_level = Float::INFINITY
        nodes.each {|n| min_level = n.level if n.level < min_level}

        nodes.each do |n|
          hierarchy_nodes = []
          (hierarchy_nodes.unshift(n); n = n.parent) while n.level >= min_level
          hierarchy_nodes.inject(result) {|memo, hn| memo[hn] ||= {}}
        end

        reducer = lambda do |h|
          h.map {|k,v| v.empty? ? k : [k, reducer.call(v)]}
        end
        nodes = reducer.call(result)
      end

      nodes
    end

    #######
    private
    #######

    def filter_alcn(nodes, ref_node, alcn)
      alcn = [alcn].flatten.map {|a| Webgen::Common.append_path(ref_node.alcn, a)}
      nodes.select {|n| alcn.any? {|a| n =~ a}}
    end

    def filter_levels(nodes, ref_node, range)
      range = [range].flatten
      nodes.select {|n| n.level >= range.first && n.level <= range.last}
    end

  end

end
