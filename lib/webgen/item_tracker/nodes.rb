# -*- encoding: utf-8 -*-

require 'webgen/item_tracker'

module Webgen
  class ItemTracker

    # This class is used to track changes to a (nested) list of nodes.
    #
    # An item for this tracker has to consist of the following fields:
    #
    # * An array consisting of [class/module name, method name] or a string/symbol specifying a
    #   method name
    # * Options argument (use an array or hash for multiple arguments)
    # * Either :content or :meta_info, depending on whether the content or the meta info of
    #   the found nodes should be tracked.
    #
    # The list of nodes is retrieved in one of two ways, depending on the type of the first field:
    #
    # * If it is a string/symbol, it specifies the name of a method on this class. This method has
    #   to take the options hash as the only parameter.
    #
    # * If it is an array, the array has to contain a class/module name and a method name. The
    #   method is invoked with the current Webgen::Website object as first and the options hash as
    #   second parameter.
    #
    # For example, consider the following statement:
    #
    #   website.ext.item_tracker.add(some_node, :nodes,
    #     ["MyModule::MyClass", "my_method"], {:some => 'options'}, :content)
    #
    # The method will be invoked like this for retrieving the nodes:
    #
    #   MyModule::MyClass.my_method(website, {:some => 'options'})
    #
    class Nodes

      def initialize(website) #:nodoc:
        @website = website
      end

      def item_id(method_name, options, type) #:nodoc:
        [method_name, options, type]
      end

      def item_data(method_name, options, type) #:nodoc:
        nodes_to_alcn(node_list(method_name, options))
      end

      def changed?(iid, old_data) #:nodoc:
        method_name, options, type = *iid
        nodes = node_list(method_name, options)
        old_data != nodes_to_alcn(nodes) ||
          nodes.flatten.any? {|n| type == :content ? @website.ext.item_tracker.node_changed?(n) : @website.ext.item_tracker.item_changed?(:node_meta_info, n.alcn)}
      end

      def node_referenced?(iid, alcn_list, node_alcn) #:nodoc:
        alcn_list.flatten.any? {|alcn| alcn == node_alcn}
      end

      # Use Webgen::NodeFinder to generate a (nested) list of nodes. The options hash has to contain
      # two keys:
      #
      # * :opts → the node finder option set
      # * :ref_alcn → the alcn of the reference node
      #
      def node_finder_option_set(options)
        @website.ext.node_finder.find(options[:opts], @website.tree[options[:ref_alcn]])
      end

      # Return the list of nodes.
      def node_list(method_name, options)
        if method_name.kind_of?(Array)
          Webgen::Utils.const_for_name(method_name.first).send(method_name.last, @website, options)
        else
          send(method_name, options)
        end
      rescue Exception
        []
      end
      private :node_list

      # Map the (nested) list of nodes to a (nested) list of alcn.
      def nodes_to_alcn(nodes) #:nodoc:
        nodes.map {|node, children| children.nil? ? node.alcn : [node.alcn, nodes_to_alcn(children)]}
      end
      private :nodes_to_alcn

    end

  end
end
