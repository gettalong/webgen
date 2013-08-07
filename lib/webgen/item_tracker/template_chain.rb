# -*- encoding: utf-8 -*-

require 'webgen/item_tracker'

module Webgen
  class ItemTracker

    # This class is used to track the template chain for a node.
    #
    # Note that only nodes that support the #template_chain method can be used (so all page,
    # template and custom webgen nodes are okay).
    #
    # The item for this tracker is the node whose template chain should be tracked, i.e. add an item
    # like this:
    #
    #   website.ext.item_tracker.add(some_node, :template_chain, other_node)
    #
    class TemplateChain

      def initialize(website) #:nodoc:
        @website = website
      end

      def item_id(node) #:nodoc:
        node.alcn
      end

      def item_data(alcn) #:nodoc:
        nodes_to_alcn(@website.tree[alcn].template_chain)
      end

      def item_changed?(alcn, old_chain) #:nodoc:
        @website.tree[alcn].nil? || item_data(alcn) != old_chain
      end

      def referenced_nodes(alcn, data) #:nodoc:
        [alcn]
      end

      def item_description(alcn, data) #:nodoc:
        "Template chain for node '#{alcn}'"
      end

      def nodes_to_alcn(nodes) #:nodoc:
        nodes.map {|node| node.alcn}
      end
      private :nodes_to_alcn

    end

  end
end
