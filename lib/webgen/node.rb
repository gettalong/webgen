require 'webgen/websiteaccess'
require 'webgen/loggable'
require 'webgen/path'
require 'uri'

module Webgen

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

    # The language of this node.
    attr_reader :lang

    # Meta information associated with the node.
    attr_reader :meta_info

    # Set by other objects to +true+ if they think the object has changed since the last run. Must
    # not be set to +false+ once it is +true+!
    attr_accessor :dirty

    # Has the node been created or has it been read from the cache?
    attr_accessor :created

    #TODO(doc): Initializes a new Node instance.
    #
    # +parent+ (immutable)::
    #    If this parameter is +nil+, then the new node acts as root. Otherwise, +parent+ has to
    #    be a valid node instance.
    # +path+ (immutable)::
    #    The path for this node. If this node is a directory, the path must have a trailing
    #    slash ('dir/'). If it is a fragment, the hash sign must be the first character of the
    #    path ('#fragment'). A compound path like 'dir/file#fragment' is also allowed as are
    #    absolute paths like 'http://myhost.com/'.
    # +canonical_name+ (immutable)::
    #    The canonical name used for resolving this node. Needs to be of the form 'basename.ext'
    #    or 'basename' where +basename+ does not contain any dots. Also, the 'basename' must not
    #    include a language part! If not set, the +path+ is used as canonical name.
    # +lang+ (immutable)::
    #    The language of the node. If not set, the node is language independent.
    # +meta_info+::
    #    A hash with meta information for the new node.
    #
    # Note: a compound path like 'dir/file' is invalid if the parent node already has a child
    # with path 'dir/'!!! (solution: just create a node with path 'file' and node 'dir/' as parent!)
    def initialize(parent, path, cn = path, meta_info = {})
      @parent = parent
      @path = path.freeze
      @cn = cn.chomp('/').freeze
      @lang = meta_info.delete('lang').freeze
      @lang = nil unless is_file?
      @meta_info = meta_info
      @children = []
      @dirty = true
      @created = true
      init_rest
    end

    # Returns the meta information item for +key+.
    def [](key)
      @meta_info[key]
    end

    # Returns the node information hash which contains information for processing the node.
    def node_info
      tree.node_info[@absolute_lcn] ||= {}
    end

    # Checks if the node is a directory.
    def is_directory?; @path[-1] == ?/; end

    # Checks if the node is a file.
    def is_file?; !is_directory? && !is_fragment?; end

    # Checks if the node is a fragment.
    def is_fragment?; @path[0] == ?# end

    # Checks if the node is the root node.
    def is_root?; self == tree.root;  end

    # Returns +true+ if the node has changed since the last webgen run.
    def changed?
      website.blackboard.dispatch_msg(:node_changed?, self) unless @dirty
      @dirty
    end

    # Returns an informative representation of the node.
    def inspect
      "<##{self.class.name}: alcn=#{@absolute_lcn}>"
    end

    # Constructs the absolute (localized) canonical name by using the +parent+ node and +name+
    # (which can be a cn or an lcn). The +type+ can be either +:alcn+ or +:acn+.
    def self.absolute_name(parent, name, type)
      if parent.kind_of?(Tree)
        ''
      else
        parent = parent.parent while parent.is_fragment? # Handle fragment nodes specially in case they are nested
        (type == :alcn ? parent.absolute_lcn : parent.absolute_cn) + (parent.is_directory? ? '/' : '') + name
      end
    end

    # Constructs an internal URL for the given +name+ which can be a acn/alcn/path.
    def self.url(name)
      url = URI::parse(name)
      url = URI::parse('webgen://webgen.localhost/') + url unless url.absolute?
      url
    end

    # Returns the node with the same canonical name but in language +lang+ or, if no such node exists,
    # an unlocalized version of the node. If no such node is found either, +nil+ is returned.
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


    # Returns the node representing the given +path+ which can be an acn/alcn. The path can be
    # absolute (i.e. starting with a slash) or relative to the current node. If no node exists for
    # the given path or if the path is invalid, +nil+ is returned.
    #
    # If the +path+ is an alcn and a node is found, it is returned. If the +path+ is an acn, the
    # correct localized node according to +lang+ is returned or if no such node exists but an
    # unlocalized version does, the unlocalized node is returned.
    def resolve(path, lang = nil)
      url = self.class.url(self.is_directory? ? File.join(@absolute_lcn, '/') : @absolute_lcn) + path

      path = url.path + (url.fragment.nil? ? '' : '#' + url.fragment)
      return nil if path =~ /^\/\.\./ || url.scheme != 'webgen' # path outside dest dir or not an internal URL (webgen://...)

      node = @tree[path, :alcn]
      if node && node.absolute_cn != path
        node
      else
        (node = @tree[path, :acn]) && node.in_lang(lang)
      end
    end

    private

    def init_rest
      @lcn = Path.lcn(@cn, @lang)
      @absolute_cn = self.class.absolute_name(@parent, @cn, :acn)
      @absolute_lcn = self.class.absolute_name(@parent, @lcn, :alcn)

      @tree = @parent
      @tree = @tree.parent while !@tree.kind_of?(Tree)

      @tree.register_node(self)
      @parent.children << self unless @parent == @tree
    end

    # Delegates missing methods to a processor. The current node is placed into the argument array as
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
