# -*- encoding: utf-8 -*-

require 'set'
require 'webgen/path'

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
  # [:limit] Value: an integer. Specifies the maximum number of nodes that should be returned.
  #          Implies <tt>flatten = true</tt>.
  #
  #          Note that fewer nodes may be returned if fewer nodes match the filter criterias.
  #
  # [:offset] Value: an integer. Specifies how many nodes from the front of the list should not be
  #           returned. Implies <tt>flatten = true</tt>.
  #
  # [:flatten] Value: anything except +nil+ or +false+. A flat list of nodes is returned if this
  #            option is set, otherwise the nodes are returned in their correct hierarchical order
  #            using nested lists: If a node has no sub nodes, only the node itself is used;
  #            otherwise a two element array containing the node and child nodes is used.
  #
  #            Note that any missing nodes in the hierarchy are automatically added so that
  #            traversing the hierarchy is always possible. For example, if we have the tree
  #            <tt>/a/b/c</tt> and only nodes +a+ and +c+ are found, node +b+ is automatically
  #            added.
  #
  # [:sort] Value: +nil+/+false+, +true+ or a meta information key. If +nil+ or +false+ is
  #         specified, no sorting is performed. If +true+ is specified, the meta information
  #         +sort_info+ (or if absent, the meta information +title+) is used for sorting. If the
  #         compared values are both integers, a numeric comparison is done, else a string
  #         comparison. If a meta information key is specified, the value of this meta information
  #         is used for comparison of nodes.
  #
  # === Filter options
  #
  # [:alcn] Value: an alcn pattern or an array of alcn patterns. Nodes that match any of the patterns
  #         are used.
  #
  # [:and] Value: a finder option set or an array of finder options sets (specifying option set
  #        names is also possible). Only nodes that appear in all specified option sets are used.
  #
  # [:lang] Value: a language code/+nil+/the special value :+node+ or an array of these values.
  #         Nodes that have one of the specified language codes, are language independent (in case
  #         of the value +nil+) or have the same language as the reference node (in case of the
  #         value :+node+) are used.
  #
  # [:levels] Value: one integer (is used as start and end level) or an array with two integers (the
  #           start and end levels). All nodes whose hierarchy levels are greater than or equal to
  #           the start level and lower than or equal to the end level are used.
  #
  # [:or] Value: a finder option set or an array of finder options sets (specifying option set names
  #       is also possible). Nodes that appear in any specified option set are additionally used.
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

    # Create a new NodeFinder object for the given website.
    def initialize(website)
      @website = website
      @mapping = {
        :alcn => :filter_alcn, :levels => :filter_levels, :lang => :filter_lang,
        :and => :filter_and, :or => :filter_or
      }
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
        @mapping[name.intern] = method
      end
      extend(mod)
    end

    # Return all nodes that match certain criterias. The parameter +opts_or_name+ can either be a
    # hash with finder options or the name of a finder option set defined using the configuration
    # option <tt>node_finder.options_sets</tt>. The node +ref_node+ is used as reference node.
    def find(opts_or_name, ref_node)
      opts = prepare_options_hash(opts_or_name)

      limit, offset, flatten, sort = remove_non_filter_options(opts)
      flatten = true if limit || offset

      nodes = filter_nodes(opts, ref_node)

      if flatten
        sort_nodes(nodes, sort)
        nodes = nodes[(offset.to_s.to_i)..(limit ? offset.to_s.to_i + limit.to_s.to_i - 1 : -1)] if limit || offset
      else
        result = {}
        min_level = 1_000_000
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
        sort_nodes(nodes, sort, false)
      end

      nodes
    end

    #######
    private
    #######

    def prepare_options_hash(opts_or_name)
      if Hash === opts_or_name
        opts_or_name.dup
      elsif @website.config['node_finder.option_sets'].has_key?(opts_or_name)
        @website.config['node_finder.option_sets'][opts_or_name].dup
      else
        raise ArgumentError, "Invalid argument supplied, expected Hash or name of search definition, not #{opts_or_name}"
      end
    end

    def remove_non_filter_options(opts)
      [opts.delete(:limit), opts.delete(:offset), opts.delete(:flatten), opts.delete(:sort)]
    end

    def filter_nodes(opts, ref_node)
      nodes = @website.tree.node_access[:alcn].values
      nodes.delete(@website.tree.dummy_root)

      opts.delete_if do |filter, value|
        if @mapping.has_key?(filter)
          nodes = send(@mapping[filter], nodes, ref_node, value)
        elsif filter.kind_of?(Symbol)
          @website.logger.warn { "Ignorning unknown node finder filter '#{filter}'" }
        end
        !filter.kind_of?(String)
      end

      nodes = filter_meta_info(nodes, ref_node, opts) unless opts.empty?
      nodes
    end

    def sort_nodes(nodes, sort, flat_mode = true)
      return unless sort
      if sort == true
        nodes.sort! do |(a,_),(b,_)|
          a = (a['sort_info'] && a['sort_info'].to_s) || a['title'] || ''
          b = (b['sort_info'] && b['sort_info'].to_s) || b['title'] || ''
          (a = a.to_i; b = b.to_i) if a !~ /\D/ && b !~ /\D/
          a <=> b
        end
      else
        nodes.sort! {|(a,_),(b,_)| a[sort] <=> b[sort]}
      end
      nodes.each {|n, children| sort_nodes(children, sort, flat_mode) if children } unless flat_mode
    end

    # :section: Filter methods

    def filter_and(nodes, ref_node, opts)
      [opts].flatten.each do |cur_opts|
        cur_opts = prepare_options_hash(cur_opts)
        remove_non_filter_options(cur_opts)
        nodes &= filter_nodes(cur_opts, ref_node)
      end
      nodes
    end

    def filter_or(nodes, ref_node, opts)
      [opts].flatten.each do |cur_opts|
        cur_opts = prepare_options_hash(cur_opts)
        remove_non_filter_options(cur_opts)
        nodes |= filter_nodes(cur_opts, ref_node)
      end
      nodes
    end

    def filter_meta_info(nodes, ref_node, mi)
      nodes.keep_if {|n| mi.all? {|key, val| n[key] == val}}
    end

    def filter_alcn(nodes, ref_node, alcn)
      alcn = [alcn].flatten.map {|a| Webgen::Path.append(ref_node.alcn, a.to_s)}
      nodes.keep_if {|n| alcn.any? {|a| n =~ a}}
    end

    def filter_levels(nodes, ref_node, range)
      range = [range].flatten.map {|i| i.to_i}
      nodes.keep_if {|n| n.level >= range.first && n.level <= range.last}
    end

    def filter_lang(nodes, ref_node, langs)
      langs = [langs].flatten.map {|l| l == :node ? ref_node.lang : l}.uniq
      nodes.keep_if {|n| langs.any? {|l| n.lang == l}}
    end

  end

end
