# -*- encoding: utf-8 -*-

require 'webgen/item_tracker'

module Webgen
  class ItemTracker

    # This class is used to track changes to the content of a node. The content of a node is changed
    # if any of its dependencies are changed.
    #
    # The item for this tracker is the alcn of the node:
    #
    #   website.ext.item_tracker.add(some_node, :node_content, my_node.alcn)
    #
    class NodeContent

      def initialize(website) #:nodoc:
        @website = website
      end

      def item_id(alcn) #:nodoc:
        alcn
      end

      def item_data(alcn) #:nodoc:
        nil
      end

      def item_changed?(alcn, old_data) #:nodoc:
        @website.tree[alcn].nil? || @website.ext.item_tracker.node_changed?(@website.tree[alcn])
      end

      def node_referenced?(alcn, nothing, node_alcn) #:nodoc:
        alcn == node_alcn
      end

    end

  end
end
