# -*- encoding: utf-8 -*-

require 'pathname'
require 'webgen/languages'
require 'webgen/path'

module Webgen

  # Represents a file, a directory or a fragment. A node always belongs to a Tree.
  #
  # All needed meta and processing information is associated with the node itself. The meta
  # information is available throught the #[] and #meta_info accessors, the processing information
  # through the #node_info accessor.
  #
  # Although node information should be changed by code, meta information must not be changed once
  # the node has been created!
  class Node

    # The parent node. This is in all but one case a Node object. The one exception is that the
    # parent of the Tree#dummy_node is a Tree object.
    attr_reader :parent

    # The child nodes of this node.
    attr_reader :children

    # The canonical name of this node.
    attr_reader :cn

    # The localized canonical name of this node.
    attr_reader :lcn

    # The absolute canonical name of this node.
    attr_reader :acn

    # The absolute localized canonical name of this node.
    attr_reader :alcn

    # The level of the node. The level specifies how deep the node is in the hierarchy.
    attr_reader :level

    # The language of this node.
    attr_reader :lang

    # Meta information associated with the node. If you need just a value for a meta information
    # key, use the #[] method.
    attr_reader :meta_info

    # Return the node information hash which contains information for processing the node.
    attr_reader :node_info

    # The full destination path of this node.
    attr_reader :dest_path

    # The tree to which this node belongs.
    attr_reader :tree


    # Create a new Node instance.
    #
    # [+parent+ (immutable)]
    #    The parent node under which this nodes should be created.
    # [+cn+ (immutable)]
    #    The canonical name for this node. Needs to be of the form <tt>basename.ext</tt> or
    #    <tt>basename</tt> where +basename+ does not contain any dots. Also, the +basename+ must not
    #    include a language part!
    # [+dest_path+ (immutable)]
    #    The full output path for this node. If this node is a directory, the path must have a
    #    trailing slash (<tt>dir/</tt>). If it is a fragment, it has to include a hash sign. This
    #    can also be an absolute path like <tt>http://myhost.com/</tt>.
    # [+meta_info+]
    #    A hash with meta information for the new node.
    #
    # The language of a node is taken from the meta information +lang+ and the entry is deleted from
    # the meta information hash. The language cannot be changed afterwards! If no +lang+ key is
    # found, the node is unlocalized.
    def initialize(parent, cn, dest_path, meta_info = {})
      @parent = parent
      @children = []
      @cn = cn.freeze
      @dest_path = dest_path.freeze

      @lang = Webgen::LanguageManager.language_for_code(meta_info.delete('lang'))
      @lang = nil unless is_file?

      @lcn = Webgen::Path.lcn(@cn, @lang).freeze
      @acn = (@parent.kind_of?(Webgen::Node) ? @parent.acn.sub(/#.*$/, '') + @cn : '').freeze
      @alcn = (@parent.kind_of?(Webgen::Node) ? @parent.alcn.sub(/#.*$/, '') + @lcn : '').freeze

      @meta_info = meta_info
      @node_info = {}

      @level = -1
      @tree = @parent
      (@level += 1; @tree = @tree.parent) while @tree.kind_of?(Webgen::Node)

      @tree.register_node(self)
      @parent.children << self unless @parent == @tree
    end

    # Return the meta information item for +key+.
    def [](key)
      @meta_info[key]
    end

    # Check if the node is a directory.
    def is_directory?
      @cn[-1] == ?/ && !is_fragment?
    end

    # Check if the node is a file.
    def is_file?
      !is_directory? && !is_fragment?
    end

    # Check if the node is a fragment.
    def is_fragment?
      @cn[0] == ?#
    end

    # Check if the node is the root node.
    def is_root?
      self == tree.root
    end

    # Return the string representation of the node which is just the #alcn.
    def to_s
      @alcn
    end

    def inspect #:nodoc:
      "<##{self.class.name}: alcn=#{@alcn}>"
    end

    # Return +true+ if the #alcn matches the pattern. See Webgen::Path.matches_pattern? for
    # more information.
    def =~(pattern)
      Webgen::Path.matches_pattern?(@alcn, pattern)
    end

    # Return the node representing the given +path+ in the given language. The path can be absolute
    # (i.e. starting with a slash) or relative to the current node. Relative paths are made absolute
    # by using the #alcn of the current node. If the +lang+ parameter is not used, it defaults to
    # the language of the current node.
    #
    # Seee Tree#resolve_node for detailed information on how the correct node for the path is found.
    def resolve(path, lang = @lang)
      @tree.resolve_node(Webgen::Path.append(@alcn, path), lang)
    end

    # Return the relative path to the given path +other+. The parameter +other+ can be a Node or an
    # object that responds to the :+to_str+ method.
    def route_to(other)
      my_url = Webgen::Path.url(@dest_path)
      other_url = if other.kind_of?(Webgen::Node)
                    Webgen::Path.url(other.proxy_node(@lang).dest_path)
                  elsif other.respond_to?(:to_str)
                    my_url + other.to_str
                  else
                    raise ArgumentError, "improper class for argument"
                  end

      # resolve any '.' and '..' paths in the target url
      if other_url.path =~ /\/\.\.?\// && other_url.scheme == 'webgen'
        other_url.path = Pathname.new(other_url.path).cleanpath.to_s
      end
      route = my_url.route_to(other_url).to_s
      (route == '' ? File.basename(@dest_path) : route)
    end

    # Return the proxy node in language +lang+. This node should be used, for example, when routing
    # to this node. The proxy node is found by using the +proxy_path+ meta information. This meta
    # information is usually set on directories to specify the node that should be used for the
    # "directory index".
    def proxy_node(lang = @lang)
      proxy_path = self['proxy_path']
      if proxy_path.nil?
        self
      else
        pnode = resolve(proxy_path, lang)
        if !pnode
          tree.website.logger(:warn) { "Proxy node specified by path '#{proxy_path}' for <#{alcn}> not found" }
        end
        pnode || self
      end
    end

    # TODO: the link_to method should be removed from the class. All methods for outputting HTML
    # should be in separate module and depend on a mime-type because they should return something
    # different for a different mime-type (e.g. PDF)

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
    # to the <tt>node.proxy_node</tt> call for getting the linked-to node instead of this node's
    # +lang+ attribute. *Note*: this is only useful when linking to a directory.
    def link_to(node, attr = {})
      attr = node['link_attrs'].merge(attr) if node['link_attrs'].kind_of?(Hash)
      rnode = node.proxy_node(attr[:lang] || @lang)
      link_text = attr[:link_text] || (rnode != node && rnode['routed_title']) || node['title']
      attr.delete_if {|k,v| k.kind_of?(Symbol)}

      use_link = (rnode != self || tree.website.config['website.link_to_current_page'])
      attr['href'] = self.route_to(rnode) if use_link
      attrs = attr.collect {|name,value| "#{name.to_s}=\"#{value}\"" }.sort.unshift('').join(' ')
      (use_link ? "<a#{attrs}>#{link_text}</a>" : "<span#{attrs}>#{link_text}</span>")
    end

    #######
    private
    #######

    # Delegate missing methods to the associated path handler. The current node is placed into the
    # argument array as the first argument before the method +name+ is invoked on the path handler.
    def method_missing(name, *args, &block)
      if node_info[:path_handler]
        node_info[:path_handler].send(name, *([self] + args), &block)
      else
        super
      end
    end

  end

end
