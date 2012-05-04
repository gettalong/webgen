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
      @node_access = {:alcn => {}, :acn => {}, :dest_path => {}, :translation_key => {}}
      @dummy_root = Node.new(self, '', '')
    end

    # The real root node of the tree.
    def root
      @dummy_root.children.first
    end

    # Access a node via a +path+ of a specific +type+. If type is +:alcn+ then +path+ has to be an
    # absolute localized canonical name, if type is +acn+ then +path+ has to be an absolute
    # canonical name and if type is +:dest_path+ then +path+ needs to be a destination path.
    #
    # Returns the requested Node or +nil+ if such a node does not exist.
    def node(path, type = :alcn)
      case type
      when :alcn then @node_access[type][path]
      when :acn then @node_access[type][path] && @node_access[type][path].first
      when :dest_path then @node_access[type][path]
      else
        raise ArgumentError, "Unknown type '#{type}' for resolving path <#{path}>"
      end
    end
    alias_method :[], :node

    # Return the node representing the given +path+ which can be an alcn/acn/destination path (name
    # resolution is done in the specified order). The path has to be absolute, i.e. starting with a
    # slash.
    #
    # If the +path+ is an alcn and a node is found, it is returned. If the +path+ is an acn, the
    # correct localized node according to +lang+ is returned or if no such node exists but an
    # unlocalized version does, the unlocalized node is returned. If the +path+ is a destination
    # path, the node with this destination path is returned.
    #
    # If no node is found for the given path or if the path is invalid, +nil+ is returned.
    def resolve_node(path, lang)
      node = self.node(path, :alcn)
      if !node || node.acn == path
        (node = (self.node(path, :acn) || self.node(path + '/', :acn))) && (node = translate_node(node, lang))
      end
      node = self.node(path, :dest_path) if !node
      node
    end

    # Return the translation of the node to the language +lang+ or, if no such node exists, an
    # unlocalized version of the node. If no such node is found either, +nil+ is returned.
    def translate_node(node, lang)
      avail = @node_access[:translation_key][translation_key(node)]
      avail.find do |n|
        n = n.parent while n.is_fragment?
        n.lang == lang
      end || avail.find do |n|
        n = n.parent while n.is_fragment?
        n.lang.nil?
      end
    end

    # Return all translations of the node.
    def translations(node)
      @node_access[:translation_key][translation_key(node)].dup
    end

    # Utility method called by Node#initialize. This method should not be used directly!
    def register_node(node)
      if @node_access[:alcn].has_key?(node.alcn)
        raise "Can't have two nodes with same alcn: #{node}"
      else
        @node_access[:alcn][node.alcn] = node
      end
      (@node_access[:acn][node.acn] ||= []) << node
      (@node_access[:translation_key][translation_key(node)] ||= []) << node
      if node.meta_info['no_output']
        # ignore node dest path
      elsif @node_access[:dest_path].has_key?(node.dest_path)
        raise "Can't have two nodes with same destination path: #{node.dest_path}"
      else
        @node_access[:dest_path][node.dest_path] = node
      end
    end

    # Return the translation key for the node.
    def translation_key(node)
      node.meta_info['translation_key'] || node.acn
    end
    private :translation_key

    # Delete the node and all of its children from the tree.
    #
    # The message <tt>:before_node_deleted</tt> is sent with the to-be-deleted node before the node
    # is actually deleted from the tree.
    def delete_node(node)
      return if node.nil? || !node.kind_of?(Node) || node == @dummy_root

      node.children.dup.each {|child| delete_node(child)}

      @website.blackboard.dispatch_msg(:before_node_deleted, node)
      node.parent.children.delete(node)
      @node_access[:alcn].delete(node.alcn)
      @node_access[:acn][node.acn].delete(node)
      @node_access[:translation_key][translation_key(node)].delete(node)
      @node_access[:dest_path].delete(node.dest_path) unless node.meta_info['no_output']
    end

  end

end
