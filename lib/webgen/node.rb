require 'webgen/websiteaccess'
require 'webgen/loggable'
require 'webgen/path'
require 'uri'
require 'set'
require 'pathname'

module Webgen

  # Represents a file, a directory or a fragment. A node always belongs to a Tree.
  class Node

    include WebsiteAccess
    include Loggable

    # The parent node.
    attr_reader :parent

    # The children of this node.
    attr_reader :children

    # The full output path of this node.
    attr_reader :path

    # The tree to which this node belongs.
    attr_reader :tree

    # The canonical name of this node.
    attr_reader :cn

    # The absolute canonical name of this node.
    attr_reader :absolute_cn

    # The localized canonical name of this node.
    attr_reader :lcn

    # The absolute localized canonical name of this node.
    attr_reader :absolute_lcn

    # The level of the node. The level specifies how deep the node is in the hierarchy.
    attr_reader :level

    # The language of this node.
    attr_reader :lang

    # Meta information associated with the node.
    attr_reader :meta_info

    # Create a new Node instance.
    #
    # +parent+ (immutable)::
    #    The parent node under which this nodes should be created.
    # +path+ (immutable)::
    #    The full output path for this node. If this node is a directory, the path must have a
    #    trailing slash (<tt>dir/</tt>). If it is a fragment, the hash sign must be the first
    #    character of the path (<tt>#fragment</tt>). This can also be an absolute path like
    #    <tt>http://myhost.com/</tt>.
    # +cn+ (immutable)::
    #    The canonical name for this node. Needs to be of the form <tt>basename.ext</tt> or
    #    <tt>basename</tt> where +basename+ does not contain any dots. Also, the +basename+ must not
    #    include a language part!
    # +meta_info+::
    #    A hash with meta information for the new node.
    #
    # The language of a node is taken from the meta information +lang+ and the entry is deleted from
    # the meta information hash. The language cannot be changed afterwards! If no +lang+ key is
    # found, the node is language neutral.
    def initialize(parent, path, cn, meta_info = {})
      @parent = parent
      @cn = cn.chomp('/').freeze
      @children = []
      reinit(path, meta_info)
      init_rest
    end

    # Re-initializes an already initialized node and resets it to its pristine state.
    def reinit(path, meta_info = {})
      old_path = @path
      @path = path.freeze
      @lang = meta_info.delete('lang').freeze
      @lang = nil unless is_file?
      @meta_info = meta_info
      @flags = Set.new([:dirty, :created])
      if @tree
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
      tree.node_info[@absolute_lcn] ||= {}
    end

    # Check if the node is a directory.
    def is_directory?; @path[-1] == ?/; end

    # Check if the node is a file.
    def is_file?; !is_directory? && !is_fragment?; end

    # Check if the node is a fragment.
    def is_fragment?; @cn[0] == ?# end

    # Check if the node is the root node.
    def is_root?; self == tree.root;  end

    # Check if the node is flagged with one of the following:
    #
    # :created:: Has the node been created or has it been read from the cache?
    # :dirty:: Set by other objects to +true+ if they think the object has changed since the last
    #          run. Must not be set to +false+ once it is +true+!
    # :dirty_meta_info:: Set by other objects to +true+ if the meta information of the node has
    #                    changed since the last run. Must not be set to +false+ once it is +true+!
    def flagged(key)
      @flags.include?(key)
    end

    # Flag the node with the +keys+. See #flagged for valid keys.
    def flag(*keys)
      @flags += keys
    end

    # Remove the flags +keys+ from the node.
    def unflag(*keys)
      @flags.subtract(keys)
    end

    # Return +true+ if the node has changed since the last webgen run. If it has changed, +dirty+ is
    # set to +true+.
    def changed?
      if_not_checked(:node) do
        flag(:dirty) if meta_info_changed? ||
          node_info[:used_nodes].any? {|n| n != @absolute_lcn && (!tree[n] || tree[n].changed?)}
        website.blackboard.dispatch_msg(:node_changed?, self) unless flagged(:dirty)
      end
      flagged(:dirty)
    end

    # Return +true+ if the meta information of the node has changed.
    def meta_info_changed?
      if_not_checked(:meta_info) do
        flag(:dirty_meta_info) if node_info[:used_meta_info_nodes].any? do |n|
          n != @absolute_lcn && (!tree[n] || tree[n].meta_info_changed?)
        end
        website.blackboard.dispatch_msg(:node_meta_info_changed?, self) unless flagged(:dirty_meta_info)
      end
      flagged(:dirty_meta_info)
    end

    # Return an informative representation of the node.
    def inspect
      "<##{self.class.name}: alcn=#{@absolute_lcn}>"
    end

    # Return +true+ if the alcn matches the pattern. See File.fnmatch for useable patterns.
    def =~(pattern)
      File.fnmatch(pattern, @absolute_lcn, File::FNM_DOTMATCH|File::FNM_CASEFOLD|File::FNM_PATHNAME)
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

    # Construct the absolute (localized) canonical name by using the +parent+ node and +name+ (which
    # can be a cn or an lcn). The +type+ can be either +:alcn+ or +:acn+.
    def self.absolute_name(parent, name, type)
      if parent.kind_of?(Tree)
        ''
      else
        parent = parent.parent while parent.is_fragment? # Handle fragment nodes specially in case they are nested
        parent_name = (type == :alcn ? parent.absolute_lcn : parent.absolute_cn)
        parent_name + (parent_name !~ /\/$/ && (parent.is_directory? || parent == parent.tree.dummy_root) ? '/' : '') + name
      end
    end

    # Construct an internal URL for the given +name+ which can be a acn/alcn/path.
    def self.url(name)
      url = URI::parse(name)
      url = URI::parse('webgen://webgen.localhost/') + url unless url.absolute?
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
      avail = @tree.node_access[:acn][@absolute_cn]
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
    def resolve(path, lang = nil)
      url = self.class.url(self.is_directory? ? File.join(@absolute_lcn, '/') : @absolute_lcn) + path

      path = url.path + (url.fragment.nil? ? '' : '#' + url.fragment)
      path.chomp!('/') unless path == '/'
      return nil if path =~ /^\/\.\./

      node = @tree[path, :alcn]
      if node && node.absolute_cn != path
        node
      else
        (node = @tree[path, :acn]) && node.in_lang(lang)
      end
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
    # routing node is the directory index node.
    def routing_node(lang)
      if !is_directory?
        self
      else
        key = [absolute_lcn, :index_node, lang]
        vcache = website.cache.volatile
        return vcache[key] if vcache.has_key?(key)

        index_path = self.meta_info['index_path']
        if index_path.nil?
          vcache[key] = self
        else
          index_node = resolve(index_path, lang)
          if index_node
            vcache[key] = index_node
            log(:info) { "Directory index path for <#{absolute_lcn}> => <#{index_node.absolute_lcn}>" }
          else
            vcache[key] = self
            log(:warn) { "No directory index path found for directory <#{absolute_lcn}>" }
          end
        end
        vcache[key]
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
    # +lang+ attribute. Note: this is only useful when linking to a directory.
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

    #######
    private
    #######

    # Do the rest of the initialization.
    def init_rest
      @lcn = Path.lcn(@cn, @lang)
      @absolute_cn = self.class.absolute_name(@parent, @cn, :acn)
      @absolute_lcn = self.class.absolute_name(@parent, @lcn, :alcn)

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

end
