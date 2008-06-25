require 'webgen/websiteaccess'
require 'webgen/node'

module Webgen

  # Represents a tree of nodes.
  class Tree

    include WebsiteAccess

    # The dummy root. This is the default node that gets created when the Tree is created sothat the
    # real root node can be treated like any other node. It has only one child, namely the real root
    # node of the tree.
    attr_reader :dummy_root

    # Direct access to the hashes for node resolving. Only use this for reading purposes! If you
    # just want to get a specific node for an alcn/acn/output path, use #node instead.
    attr_reader :node_access

    # The hash containing processing information for each node. This is normally not accessed
    # directly but via the Node#node_info method.
    attr_reader :node_info

    # Create a new Tree object.
    def initialize
      @node_access = {:alcn => {}, :acn => {}, :path => {}}
      @node_info = {}
      @dummy_root = Node.new(self, '', '')
    end

    # The real root node of the tree.
    def root
      @dummy_root.children.first
    end

    # Access a node via a +path+ of a specific +type+. If type is +alcn+ then +path+ has to be an
    # absolute localized canonical name, if type is +acn+ then +path+ has to be an absolute
    # canonical name and if type is +path+ then +path+ needs to be an output path.
    #
    # Returns the requested Node or +nil+ if such a node does not exist.
    def node(path, type = :alcn)
      (type == :acn ? @node_access[type][path] && @node_access[type][path].first : @node_access[type][path])
    end
    alias_method :[], :node

    # A utility method called by Node#initialize. This method should not be used directly!
    def register_node(node)
      if @node_access[:alcn].has_key?(node.absolute_lcn)
        raise "Can't have two nodes with same absolute lcn: #{node.absolute_lcn}"
      else
        @node_access[:alcn][node.absolute_lcn] = node
      end
      (@node_access[:acn][node.absolute_cn] ||= []) << node
      if @node_access[:path].has_key?(node.path)
        raise "Can't have two nodes with same output path: #{node.path}" unless node['no_output']
      else
        @node_access[:path][node.path] = node
      end
    end

    # Delete the node identified by +node_or_alcn+ and all of its children from the
    # tree. Directories are only deleted if +delete_dir+ is +true+.
    def delete_node(node_or_alcn, delete_dir = false)
      n = node_or_alcn.kind_of?(Node) ? node_or_alcn : @node_access[:alcn][node_or_alcn]
      return if n.nil? || n == @dummy_root || (n.is_directory? && !delete_dir)

      n.children.dup.each {|child| delete_node(child, true)}

      website.blackboard.dispatch_msg(:before_node_deleted, n)
      n.parent.children.delete(n)
      @node_access[:alcn].delete(n.absolute_lcn)
      @node_access[:acn][n.absolute_cn].delete(n)
      @node_access[:path].delete(n.path)

      node_info.delete(n.absolute_lcn)
    end

  end

end
