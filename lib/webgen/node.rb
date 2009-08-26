# -*- encoding: utf-8 -*-

require 'webgen/websiteaccess'
require 'webgen/loggable'
require 'webgen/path'
require 'uri'
require 'set'
require 'pathname'

module Webgen

  # Represents a file, a directory or a fragment. A node always belongs to a Tree.
  #
  # All needed meta and processing information is associated with a Node. The meta information is
  # available throught the #[] and #meta_info accessors, the processing information through the
  # #node_info accessor.
  #
  # Although node information should be changed by code, it is not advised to change meta
  # information values in code since this may lead to unwanted behaviour!
  class Node

    include WebsiteAccess
    include Loggable

    # The parent node. This is in all but one case a Node object. The one exception is that the
    # parent of the Tree#dummy_node is a Tree object.
    attr_reader :parent

    # The child nodes of this node.
    attr_reader :children

    # The full output path of this node.
    attr_reader :path

    # The tree to which this node belongs.
    attr_reader :tree

    # The canonical name of this node.
    attr_reader :cn

    # The absolute canonical name of this node.
    attr_reader :acn

    # The localized canonical name of this node.
    attr_reader :lcn

    # The absolute localized canonical name of this node.
    attr_reader :alcn

    # The level of the node. The level specifies how deep the node is in the hierarchy.
    attr_reader :level

    # The language of this node.
    attr_reader :lang

    # Meta information associated with the node.
    attr_reader :meta_info

    # Create a new Node instance.
    #
    # [+parent+ (immutable)]
    #    The parent node under which this nodes should be created.
    # [+path+ (immutable)]
    #    The full output path for this node. If this node is a directory, the path must have a
    #    trailing slash (<tt>dir/</tt>). If it is a fragment, the hash sign must be the first
    #    character of the path (<tt>#fragment</tt>). This can also be an absolute path like
    #    <tt>http://myhost.com/</tt>.
    # [+cn+ (immutable)]
    #    The canonical name for this node. Needs to be of the form <tt>basename.ext</tt> or
    #    <tt>basename</tt> where +basename+ does not contain any dots. Also, the +basename+ must not
    #    include a language part!
    # [+meta_info+]
    #    A hash with meta information for the new node.
    #
    # The language of a node is taken from the meta information +lang+ and the entry is deleted from
    # the meta information hash. The language cannot be changed afterwards! If no +lang+ key is
    # found, the node is language neutral.
    def initialize(parent, path, cn, meta_info = {})
      @parent = parent
      @cn = cn.freeze
      @children = []
      reinit(path, meta_info)
      init_rest
    end

    # Re-initializes an already initialized node and resets it to its pristine state.
    def reinit(path, meta_info = {})
      old_path = @path if defined?(@path)
      @path = path.freeze
      @lang = Webgen::LanguageManager.language_for_code(meta_info.delete('lang'))
      @lang = nil unless is_file?
      @meta_info = meta_info
      @flags = Set.new([:dirty, :created])
      if defined?(@tree)
        @tree.node_access[:path].delete(old_path) if old_path
        @tree.register_path(self)
        self.node_info.clear
        self.node_info[:used_nodes] = Set.new
        self.node_info[:used_meta_info_nodes] = Set.new
      end
    end

    # Return the meta information item for +key+.
    def [](key)
      @meta_info[key]
    end

    # Assign +value+ to the meta information item for +key+.
    def []=(key, value)
      @meta_info[key] = value
    end

    # Return the node information hash which contains information for processing the node.
    def node_info
      tree.node_info[@alcn] ||= {}
    end

    # Check if the node is a directory.
    def is_directory?; @path[-1] == ?/ && !is_fragment?; end

    # Check if the node is a file.
    def is_file?; !is_directory? && !is_fragment?; end

    # Check if the node is a fragment.
    def is_fragment?; @cn[0] == ?# end

    # Check if the node is the root node.
    def is_root?; self == tree.root;  end

    # Check if the node is flagged with one of the following:
    #
    # [:created] Has the node been created or has it been read from the cache?
    # [:reinit] Does the node need to be reinitialized?
    # [:dirty] Set by other objects to +true+ if they think the object has changed since the last
    #          run. Must not be set to +false+ once it is +true+!
    # [:dirty_meta_info] Set by other objects to +true+ if the meta information of the node has
    #                    changed since the last run. Must not be set to +false+ once it is +true+!
    def flagged?(key)
      @flags.include?(key)
    end

    # Flag the node with the +keys+ and dispatch the message <tt>:node_flagged</tt> with +self+ and
    # +keys+ as arguments. See #flagged for valid keys.
    def flag(*keys)
      @flags += keys
      website.blackboard.dispatch_msg(:node_flagged, self, keys)
    end

    # Remove the flags +keys+ from the node and dispatch the message <tt>:node_unflagged</tt> with
    # +self+ and +keys+ as arguments.
    def unflag(*keys)
      @flags.subtract(keys)
      website.blackboard.dispatch_msg(:node_unflagged, self, keys)
    end

    # Return +true+ if the node has changed since the last webgen run. If it has changed, +dirty+ is
    # set to +true+.
    #
    # Sends the message <tt>:node_changed?</tt> with +self+ as argument unless the node is already
    # dirty. A listener to this message should set the flag <tt>:dirty</tt> on the passed node if he
    # thinks it is dirty.
    def changed?
      if_not_checked(:node) do
        flag(:dirty) if meta_info_changed? || user_nodes_changed? ||
          node_info[:used_nodes].any? {|n| n != @alcn && (!tree[n] || tree[n].changed?)} ||
          node_info[:used_meta_info_nodes].any? {|n| n != @alcn && (!tree[n] || tree[n].meta_info_changed?)}
        website.blackboard.dispatch_msg(:node_changed?, self) unless flagged?(:dirty)
      end
      flagged?(:dirty)
    end

    # Return +true+ if any node matching a pattern from the meta information +used_nodes+ has changed.
    def user_nodes_changed?
      pattern = [@meta_info['used_nodes']].flatten.compact.collect {|pat| Webgen::Path.make_absolute(parent.alcn, pat)}
      tree.node_access[:alcn].any? do |path, n|
        pattern.any? {|pat| n =~ pat && n.changed?}
      end if pattern.length > 0
    end
    private :user_nodes_changed?

    # Return +true+ if the meta information of the node has changed.
    #
    # Sends the message <tt>:node_meta_info_changed?</tt> with +self+ as argument unless the meta
    # information of the node is already dirty. A listener to this message should set the flag
    # <tt>:dirt_meta_info</tt> on the passed node if he thinks that the node's meta information is
    # dirty.
    def meta_info_changed?
      if_not_checked(:meta_info) do
        website.blackboard.dispatch_msg(:node_meta_info_changed?, self) unless flagged?(:dirty_meta_info)
      end
      flagged?(:dirty_meta_info)
    end

    # Return an informative representation of the node.
    def inspect
      "<##{self.class.name}: alcn=#{@alcn}>"
    end

    # Return +true+ if the alcn matches the pattern. See Webgen::Path.match for more information.
    def =~(pattern)
      Webgen::Path.match(@alcn, pattern)
    end

    # Sort nodes by using the meta info +sort_info+ (or +title+ if +sort_info+ is not set) of both
    # involved nodes.
    def <=>(other)
      self_so = (@meta_info['sort_info'] && @meta_info['sort_info'].to_s) || @meta_info['title'] || ''
      other_so = (other['sort_info'] && other['sort_info'].to_s) || other['title'] || ''
      if self_so !~ /\D/ && other_so !~ /\D/
        self_so = self_so.to_i
        other_so = other_so.to_i
      end
      self_so <=> other_so
    end

    # This pattern is the the same as URI::UNSAFE except that the hash character (#) is also
    # not escaped. This is needed sothat paths with fragments work correctly.
    URL_UNSAFE_PATTERN = Regexp.new("[^#{URI::PATTERN::UNRESERVED}#{URI::PATTERN::RESERVED}#]") # :nodoc:

    # Construct an internal URL for the given +name+ which can be an acn/alcn/path. If the parameter
    # +make_absolute+ is +true+, then a relative URL will be made absolute by prepending the special
    # URL <tt>webgen:://webgen.localhost/</tt>.
    def self.url(name, make_absolute = true)
      url = URI::parse(URI::escape(name, URL_UNSAFE_PATTERN))
      url = URI::parse('webgen://webgen.localhost/') + url unless url.absolute? || !make_absolute
      url
    end


    # Check if the this node is in the subtree which is spanned by +node+. The check is performed
    # using only the +parent+ information of the involved nodes, NOT the actual path/alcn values!
    def in_subtree_of?(node)
      temp = self
      temp = temp.parent while temp != tree.dummy_root && temp != node
      temp != tree.dummy_root
    end

    # Return the node with the same canonical name but in language +lang+ or, if no such node
    # exists, an unlocalized version of the node. If no such node is found either, +nil+ is
    # returned.
    def in_lang(lang)
      avail = @tree.node_access[:acn][@acn]
      avail.find do |n|
        n = n.parent while n.is_fragment?
        n.lang == lang
      end || avail.find do |n|
        n = n.parent while n.is_fragment?
        n.lang.nil?
      end
    end

    # Return the node representing the given +path+ which can be an acn/alcn. The path can be
    # absolute (i.e. starting with a slash) or relative to the current node. If no node exists for
    # the given path or if the path is invalid, +nil+ is returned.
    #
    # If the +path+ is an alcn and a node is found, it is returned. If the +path+ is an acn, the
    # correct localized node according to +lang+ is returned or if no such node exists but an
    # unlocalized version does, the unlocalized node is returned.
    def resolve(path, lang = nil, use_passive_sources = true)
      orig_path = path
      url = self.class.url(@alcn) + self.class.url(path, false)

      path = url.path + (url.fragment.nil? ? '' : '#' + url.fragment)
      return nil if path =~ /^\/\.\./

      node = @tree[path, :alcn]
      if !node || node.acn == path
        (node = (@tree[path, :acn] || @tree[path + '/', :acn])) && (node = node.in_lang(lang))
      end
      if !node && use_passive_sources && !website.config['passive_sources'].empty?
        nodes = website.blackboard.invoke(:create_nodes_from_paths, [path])
        node = resolve(orig_path, lang, false)
        node.node_info[:used_meta_info_nodes] += nodes.collect {|n| n.alcn} if node
      end
      node
    end

    # Return the relative path to the given path +other+. The parameter +other+ can be a Node or a
    # String.
    def route_to(other)
      my_url = self.class.url(@path)
      other_url = if other.kind_of?(Node)
                    self.class.url(other.routing_node(@lang).path)
                  elsif other.kind_of?(String)
                    my_url + other
                  else
                    raise ArgumentError, "improper class for argument"
                  end

      # resolve any '.' and '..' paths in the target url
      if other_url.path =~ /\/\.\.?\// && other_url.scheme == 'webgen'
        other_url.path = Pathname.new(other_url.path).cleanpath.to_s
      end
      route = my_url.route_to(other_url).to_s
      (route == '' ? File.basename(self.path) : route)
    end

    # Return the routing node in language +lang+ which is the node that is used when routing to this
    # node. The returned node can differ from the node itself in case of a directory where the
    # routing node is the directory index node. If +show_warning+ is +true+ and this node is a
    # directory node, then a warning is logged if no associated index file is found.
    def routing_node(lang, log_warning = true)
      if !is_directory?
        self
      else
        key = [alcn, :index_node, lang]
        vcache = website.cache.volatile
        return vcache[key] if vcache.has_key?(key)

        index_path = self.meta_info['index_path']
        if index_path.nil?
          vcache[key] = self
        else
          index_node = resolve(index_path, lang)
          if index_node
            vcache[key] = index_node
            log(:info) { "Directory index path for <#{alcn}> => <#{index_node.alcn}>" }
          elsif log_warning
            vcache[key] = self
            log(:warn) { "No directory index path found for directory <#{alcn}>" }
          end
        end
        vcache[key] || self
      end
    end

    # Return a HTML link from this node to the +node+ or, if this node and +node+ are the same and
    # the parameter <tt>website.link_to_current_page</tt> is +false+, a +span+ element with the link
    # text.
    #
    # You can optionally specify additional attributes for the HTML element in the +attr+ Hash.
    # Also, the meta information +link_attrs+ of the given +node+ is used, if available, to set
    # attributes. However, the +attr+ parameter takes precedence over the +link_attrs+ meta
    # information. Be aware that all key-value pairs with Symbol keys are removed before the
    # attributes are written. Therefore you always need to specify general attributes with Strings!
    #
    # If the special value <tt>:link_text</tt> is present in the attributes, it will be used as the
    # link text; otherwise the title of the +node+ will be used.
    #
    # If the special value <tt>:lang</tt> is present in the attributes, it will be used as parameter
    # to the <tt>node.routing_node</tt> call for getting the linked-to node instead of this node's
    # +lang+ attribute. *Note*: this is only useful when linking to a directory.
    def link_to(node, attr = {})
      attr = node['link_attrs'].merge(attr) if node['link_attrs'].kind_of?(Hash)
      rnode = node.routing_node(attr[:lang] || @lang)
      link_text = attr[:link_text] || (rnode != node && rnode['routed_title']) || node['title']
      attr.delete_if {|k,v| k.kind_of?(Symbol)}

      use_link = (rnode != self || website.config['website.link_to_current_page'])
      attr['href'] = self.route_to(rnode) if use_link
      attrs = attr.collect {|name,value| "#{name.to_s}=\"#{value}\"" }.sort.unshift('').join(' ')
      (use_link ? "<a#{attrs}>#{link_text}</a>" : "<span#{attrs}>#{link_text}</span>")
    end

    def find(opts = {})
      if opts[:alcn]
        opts[:alcn] = Path.make_absolute(is_directory? ? alcn : parent.alcn.sub(/#.*$/, ''), opts[:alcn].to_s)
      end
      opts[:levels] = 100000 unless opts.has_key?(:levels)

      result = find_nodes(opts, nil, 1)
      result.flatten! if result && (opts[:limit] || opts[:offset])
      result.sort!(opts[:sort]) if result
      result.children = result.children[(opts[:offset].to_s.to_i)..(opts[:limit] ? opts[:offset].to_s.to_i + opts[:limit].to_s.to_i - 1 : -1)]
      result
    end

    def find_nodes(opts, parent, level)
      result = ProxyNode.new(parent, self)

      children.each do |child|
        c_result = child.find_nodes(opts, result, level + 1)
        result.children << c_result unless c_result.nil?
      end if opts[:levels] && level <= opts[:levels]

      (!result.children.empty? || find_match?(opts) ? result : nil)
    end
    protected :find_nodes

    def find_match?(opts)
      (!opts[:alcn] || self =~ opts[:alcn])
    end
    private :find_match?

    #######
    private
    #######

    # Do the rest of the initialization.
    def init_rest
      @lcn = Path.lcn(@cn, @lang)
      @acn = (@parent.kind_of?(Tree) ? '' : @parent.acn.sub(/#.*$/, '') + @cn)
      @alcn = (@parent.kind_of?(Tree) ? '' : @parent.alcn.sub(/#.*$/, '') + @lcn)

      @level = -1
      @tree = @parent
      (@level += 1; @tree = @tree.parent) while !@tree.kind_of?(Tree)

      @tree.register_node(self)
      @parent.children << self unless @parent == @tree

      self.node_info[:used_nodes] = Set.new
      self.node_info[:used_meta_info_nodes] = Set.new
    end

    # Only run the code in the block if this node has not already been checked. Different checks are
    # supported by setting a different +type+ value.
    def if_not_checked(type)
      array = (website.cache.volatile[:node_change_checking] ||= {})[type] ||= []
      if !array.include?(self)
        array << self
        yield
        array.delete(self)
      end
    end

    # Delegate missing methods to a processor. The current node is placed into the argument array as
    # the first argument before the method +name+ is invoked on the processor.
    def method_missing(name, *args, &block)
      if node_info[:processor]
        website.cache.instance(node_info[:processor]).send(name, *([self] + args), &block)
      else
        super
      end
    end

  end

  # Encapsulates a node. This class is needed when a hierarchy of nodes should be created but the
  # original hierarchy should not be destroyed.
  class ProxyNode

    # Array of child proxy nodes.
    attr_accessor :children

    # The parent proxy node.
    attr_accessor :parent

    # The encapsulated node.
    attr_reader :node

    # Create a new proxy node under +parent+ (also has to be a ProxyNode object) for the real node
    # +node+.
    def initialize(parent, node)
      @parent = parent
      @node = node
      @children = []
    end

    # Sort recursively all children of the node using the wrapped nodes. If +value+ is +false+, no
    # sorting is done at all. If it is +true+, then the default sort mechanism is used (see
    # Node#<=>). Otherwise +value+ has to be a meta information key on which should be sorted.
    def sort!(value = true)
      return self unless value

      if value.kind_of?(String)
        self.children.sort! do |a,b|
          aval, bval = a.node[value].to_s, b.node[value].to_s
          if aval !~ /\D/ && aval !~ /\D/
            aval = aval.to_i
            bval = bval.to_i
          end
          aval <=> bval
        end
      else
        self.children.sort! {|a,b| a.node <=> b.node}
      end
      self.children.each {|child| child.sort!(value)}
      self
    end

    # Turn the hierarchy of proxy nodes into a flat list.
    def flatten!
      result = []
      while !self.children.empty?
        result << self.children.shift
        result.last.parent = self
        self.children.unshift(*result.last.children)
        result.last.children = []
      end
      self.children = result
    end

    # Return the hierarchy under this node as nested list of alcn values.
    def to_list
      self.children.inject([]) {|temp, n| temp << n.node.alcn; temp += ((t = n.to_list).empty? ? [] : [t]) }
    end

  end

end
