require 'webgen/websiteaccess'
require 'webgen/node'

module Webgen

  class Tree

    include WebsiteAccess

    # The dummy root.
    attr_reader :dummy_root

    # Direct access to the hashes for node resolving. Only use this for reading purposes! If you
    # just want to get a specific node for an alcn/acn/output path, use #node instead.
    attr_reader :node_access

    # Processing information for a node.
    attr_reader :node_info

    def initialize
      #TODO: ev. remove default creation of [] for :acn
      @node_access = {:alcn => {}, :acn => Hash.new {|h,k| h[k] = []}, :path => {}}
      @node_info = {}
      @dummy_root = Node.new(self, '')
    end

    # The root node of the tree.
    def root
      @dummy_root.children.first
    end

    # Access a node via a +path+ of a specific +type+. If type is +alcn+ then +path+ has to be an
    # absolute localized canonical name, if type is +acn+ then +path+ has to be an absolute
    # canonical name and if type is +path+ then +path+ needs to be an output path.
    def node(path, type = :alcn)
      (type == :acn ? @node_access[type][path].first : @node_access[type][path])
    end
    alias_method :[], :node

    # A utility method called by Node#initialize. This method should not be used directly!
    def register_node(node)
      if @node_access[:alcn].has_key?(node.absolute_lcn)
        raise "Can't have two nodes with same absolute lcn: #{node.absolute_lcn}"
      else
        @node_access[:alcn][node.absolute_lcn] = node
      end
      @node_access[:acn][node.absolute_cn] << node
      if @node_access[:path].has_key?(node.path)
        raise "Can't have two nodes with same output path: #{node.path}"
      else
        @node_access[:path][node.path] = node
      end
    end

    # Deletes the node identified by +node_or_alcn+ and all of its children from the tree. Deletes
    # directories only if +delete_dir+ is set to +true+.
    def delete_node(node_or_alcn, delete_dir = false)
      n = node_or_alcn.kind_of?(Node) ? node_or_alcn : @node_access[:alcn][node_or_alcn]
      return if n.nil? || n == @dummy_root || (n.is_directory? && !delete_dir)

      n.children.each {|child| delete_node(child, true)}

      website.blackboard.dispatch_msg(:before_node_deleted, n)
      n.parent.children.delete(n)
      @node_access[:alcn].delete(n.absolute_lcn)
      @node_access[:acn][n.absolute_cn].delete(n)
      @node_access[:path].delete(n.path)

      node_info.delete(n.absolute_lcn)
    end

  end

end
