# -*- encoding: utf-8 -*-

require 'webgen/node'

module Webgen

  # Represents a tree of nodes.
  class Tree

    # The dummy root. This is the default node that gets created when the Tree is created so that
    # the real root node can be treated like any other node. It has only one child, namely the real
    # root node of the tree.
    attr_reader :dummy_root

    # Direct access to the hashes for node resolving. Only use this for reading purposes! If you
    # just want to get a specific node for an alcn/acn/destination path, use #node instead.
    attr_reader :node_access

    # The website to which the Tree object belongs.
    attr_reader :website

    # Create a new Tree object for the website.
    def initialize(website)
      @website = website
      @node_access = {:alcn => {}, :acn => {}, :dest_path => {}}
      @dummy_root = Node.new(self, '', '')
    end

    # The real root node of the tree.
    def root
      @dummy_root.children.first
    end

    # Access a node via a +path+ of a specific +type+. If type is +alcn+ then +path+ has to be an
    # absolute localized canonical name, if type is +acn+ then +path+ has to be an absolute
    # canonical name and if type is +path+ then +path+ needs to be a destination path.
    #
    # Returns the requested Node or +nil+ if such a node does not exist.
    def node(path, type = :alcn)
      (type == :acn ? @node_access[type][path] && @node_access[type][path].first : @node_access[type][path])
    end
    alias_method :[], :node

    # Utility method called by Node#initialize. This method should not be used directly!
    def register_node(node)
      if @node_access[:alcn].has_key?(node.alcn)
        raise "Can't have two nodes with same alcn: #{node}"
      else
        @node_access[:alcn][node.alcn] = node
      end
      (@node_access[:acn][node.acn] ||= []) << node
      if @node_access[:dest_path].has_key?(node.dest_path)
        raise "Can't have two nodes with same destination path: #{node.dest_path}"
      else
        @node_access[:dest_path][node.dest_path] = node
      end
    end

  end

end
