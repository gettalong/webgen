# -*- encoding: utf-8 -*-

require 'webgen/path'

module Webgen

  # Used for finding nodes that match certain criterias.
  #
  # == About
  #
  # This extension class is used for finding nodes that match certain criterias (all nodes are used
  # if no filter options are specified) when calling the #find method. There are some built-in
  # filters but one can also provide custom filters via #add_filter_module.
  #
  # The found nodes are either returned in a flat list or hierarchical in nested lists (if a node
  # has no child nodes, only the node itself is used; otherwise a two element array containing the
  # node and child nodes is used). Sorting, limiting the number of returned nodes and using an
  # offset are also possible.
  #
  # *Note* that results are cached in the volatile cache of the Cache instance!
  #
  # == Finder options
  #
  # Following is the list of all finder options. Note that there may also be other 3rd party node
  # filters available if you are using extension bundles!
  #
  # === Non-filter options
  #
  # These options are not used for filtering out nodes but provide additional functionality.
  #
  # [:limit]
  #   Value: an integer. Specifies the maximum number of nodes that should be returned. Implies
  #   'flatten = true'.
  #
  #   Note that fewer nodes may be returned if fewer nodes match the filter criterias.
  #
  # [:offset]
  #   Value: an integer. Specifies how many nodes from the front of the list should *not* be
  #   returned. Implies 'flatten = true'.
  #
  # [:levels]
  #   Value: one integer (is used as start and end level) or an array with two integers (the start
  #   and end levels). All nodes whose hierarchy level in the returned node hierarchy is greater
  #   than or equal to the start level and lower than or equal to the end level are used.
  #
  #   Only used when the node hierarchy is not flattened.
  #
  # [:flatten]
  #   Value: anything except +nil+ or +false+. A flat list of nodes is returned if this option is
  #   set, otherwise the nodes are returned in their correct hierarchical order using nested lists.
  #
  #   Note that any missing nodes in the hierarchy are automatically added so that traversing the
  #   hierarchy is always possible. For example, if we have the tree '/a/b/c' and only nodes +a+ and
  #   +c+ are found, node +b+ is automatically added.
  #
  # [:sort]
  #   Value: +nil+/+false+, +true+ or a meta information key. If +nil+ or +false+ is specified, no
  #   sorting is performed. If +true+ is specified, the meta information +sort_info+ (or if absent,
  #   the meta information +title+) is used for sorting. If the compared values are both integers, a
  #   numeric comparison is done, else a string comparison. If a meta information key is specified,
  #   the value of this meta information is used for comparison of nodes (again, if both compared
  #   values are integers, a numeric comparison is done, else a string comparison).
  #
  # [:reverse]
  #   Value: +true+ of +false+/+nil+. If this option is set to +true+, the sort order is reversed.
  #
  # === Filter options
  #
  # These options are used for filtering the nodes. All nodes are used by default if no filter
  # options are specified.
  #
  # [:alcn]
  #   Value: an alcn pattern or an array of alcn patterns. Nodes that match any of the patterns are
  #   used.
  #
  # [:lang]
  #   Value: a language code/+nil+/the special value +node+ or an array of these values. Nodes that
  #   have one of the specified language codes, are language independent (in case of the value
  #   +nil+) or have the same language as the reference node (in case of the value +node+) are
  #   used.
  #
  # [:mi]
  #   Value: a hash with meta information key to value mappings. Only nodes that have the same
  #   values for all meta information keys are used.
  #
  # [:or]
  #   Value: a finder option set or an array of finder options sets (specifying option set names is
  #   also possible). Nodes that appear in any specified option set are additionally used.
  #
  # [:and]
  #   Value: a finder option set or an array of finder options sets (specifying option set names is
  #   also possible). Only nodes that appear in all specified option sets are used.
  #
  # [:not]
  #   Value: a finder option set or an array of finder options sets (specifying option set names is
  #   also possible). Only nodes that do not appear in any specified option set are used.
  #
  # [:absolute_levels]
  #   Value: one integer (is used as start and end level) or an array with two integers (the start
  #   and end levels). All nodes whose hierarchy level in the node tree are greater than or equal to
  #   the start level and lower than or equal to the end level are used.
  #
  #   Negative numbers, where -1 stands for the reference node, -2 for its parent node and so on,
  #   can also be used.
  #
  # [:ancestors]
  #   Value: +true+ or +false+/+nil+. If this filter option is set to +true+, only nodes that are
  #   ancestors of the reference node are used. The reference node itself is used as well.
  #
  # [:descendants]
  #   Value: +true+ or +false+/+nil+. If this filter option is set to +true+, only nodes that are
  #   descendants of the reference node are used. The reference node itself is used as well.
  #
  # [:siblings]
  #   Value: +true+, +false+/+nil+, or an array with two integers. If this filter option is set to
  #   +true+, only nodes that are sibling node of the reference node are used. The reference node
  #   itself is used as well. If set to +false+ or +nil+, this filter is ignored.
  #
  #   If an array with two numbers is specified, all sibling nodes of the reference node or its
  #   parent nodes the hierarchy level of which lies between these numbers are used. The parent
  #   nodes and the reference node are used as well if their level lies between the numbers.
  #   Counting starts at zero (the root node).
  #
  #   Negative numbers, where -1 stands for the reference node, -2 for its parent node and so on,
  #   can also be used.
  #
  # == Implementing a filter module
  #
  # Implementing a filter module is very easy. Just create a module that contains your filter
  # methods and tell the NodeFinder object about it using the #add_filter_module method. A filter
  # method needs to take three arguments: an array of nodes, the reference node and the filter
  # value.
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
        :alcn => :filter_alcn, :absolute_levels => :filter_absolute_levels, :lang => :filter_lang,
        :and => :filter_and, :or => :filter_or, :not => :filter_not,
        :ancestors => :filter_ancestors, :descendants => :filter_descendants,
        :siblings => :filter_siblings,
        :mi => :filter_meta_info
      }
    end

    # Add a module with filter methods.
    #
    # The parameter +mapping+ needs to be a hash associating unique names with the methods of the
    # given module that can be used as finder methods.
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

    # Return all nodes that match certain criterias.
    #
    # The parameter +opts_or_name+ can either be a hash with finder options or the name of a finder
    # option set defined using the configuration option 'node_finder.options_sets'. The node
    # +ref_node+ is used as reference node.
    def find(opts_or_name, ref_node)
      if result = cached_result(opts_or_name, ref_node)
        return result
      end
      opts = prepare_options_hash(opts_or_name)

      limit, offset, flatten, sort, levels, reverse = remove_non_filter_options(opts)
      flatten = true if limit || offset
      levels = [levels || [1, 1_000_000]].flatten.map {|i| i.to_i}

      nodes = filter_nodes(opts, ref_node)

      if flatten
        sort_nodes(nodes, sort, reverse)
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

        reducer = lambda do |h, level|
          if level < levels.first
            temp = h.map {|k,v| v.empty? ? nil : reducer.call(v, level + 1)}.compact
            temp.length == 1 && temp.first.kind_of?(Array) ? temp.first : temp
          elsif level < levels.last
            h.map {|k,v| v.empty? ? k : [k, reducer.call(v, level + 1)]}
          else
            h.map {|k,v| k}
          end
        end
        nodes = reducer.call(result, 1)
        sort_nodes(nodes, sort, reverse, false)
      end

      cache_result(opts_or_name, ref_node, nodes)
    end

    #######
    private
    #######

    def cached_result(opts, ref_node)
      (@website.cache.volatile[:node_finder] ||= {})[[opts, ref_node.alcn]]
    end

    def cache_result(opts, ref_node, result)
      (@website.cache.volatile[:node_finder] ||= {})[[opts, ref_node.alcn]] = result
    end

    def prepare_options_hash(opts_or_name)
      if Hash === opts_or_name
        opts_or_name.symbolize_keys
      elsif @website.config['node_finder.option_sets'].has_key?(opts_or_name)
        @website.config['node_finder.option_sets'][opts_or_name].symbolize_keys
      else
        raise ArgumentError, "Invalid argument supplied, expected Hash or name of search definition, not #{opts_or_name}"
      end
    end

    def remove_non_filter_options(opts)
      [opts.delete(:limit), opts.delete(:offset), opts.delete(:flatten),
       opts.delete(:sort), opts.delete(:levels), opts.delete(:reverse)]
    end

    def filter_nodes(opts, ref_node)
      nodes = @website.tree.node_access[:alcn].values
      nodes.delete(@website.tree.dummy_root)

      opts.each do |filter, value|
        if @mapping.has_key?(filter)
          nodes = send(@mapping[filter], nodes, ref_node, value)
        else
          @website.logger.warn { "Ignoring unknown node finder filter '#{filter}'" }
        end
      end

      nodes
    end

    def sort_nodes(nodes, sort, reverse, flat_mode = true)
      return unless sort
      if sort == true
        nodes.sort! do |(a,_),(b,_)|
          a = (a['sort_info'] && a['sort_info'].to_s) || a['title'].to_s || ''
          b = (b['sort_info'] && b['sort_info'].to_s) || b['title'].to_s || ''
          (a = a.to_i; b = b.to_i) if a !~ /\D/ && b !~ /\D/
          (reverse ? b <=> a : a <=> b)
        end
      else
        nodes.sort! do |(a,_),(b,_)|
          a, b = a[sort].to_s, b[sort].to_s
          a, b = a.to_i, b.to_i if a !~ /\D/ && b !~ /\D/
          (reverse ? b <=> a : a <=> b)
        end
      end
      nodes.each {|n, children| sort_nodes(children, sort, reverse, flat_mode) if children } unless flat_mode
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

    def filter_not(nodes, ref_node, opts)
      [opts].flatten.each do |cur_opts|
        cur_opts = prepare_options_hash(cur_opts)
        remove_non_filter_options(cur_opts)
        nodes -= filter_nodes(cur_opts, ref_node)
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

    def filter_absolute_levels(nodes, ref_node, range)
      range = [range].flatten.map {|i| (i = i.to_i) < 0 ? ref_node.level + 1 + i : i}
      nodes.keep_if {|n| n.level >= range.first && n.level <= range.last}
    end

    def filter_lang(nodes, ref_node, langs)
      langs = [langs].flatten.map {|l| l == 'node' ? ref_node.lang : l}.uniq
      nodes.keep_if {|n| langs.any? {|l| n.lang == l}}
    end

    def filter_ancestors(nodes, ref_node, enabled)
      return nodes unless enabled
      nodes = []
      node = ref_node
      until node == node.tree.dummy_root
        nodes.unshift(node)
        node = node.parent
      end
      nodes
    end

    def filter_descendants(nodes, ref_node, enabled)
      return nodes unless enabled
      nodes.keep_if do |n|
        n = n.parent while n != n.tree.dummy_root && n != ref_node
        n == ref_node
      end
    end

    def filter_siblings(nodes, ref_node, value)
      return nodes unless value
      if value == true
        nodes.keep_if {|n| n.parent == ref_node.parent}
      else
        value = [value].flatten.map {|i| (i = i.to_i) < 0 ? ref_node.level + 1 + i : i}
        nodes.keep_if do |n|
          n.level >= value.first && n.level <= value.last && (n.parent.is_ancestor_of?(ref_node) || n.is_root?)
        end
      end
    end

  end

end
