# -*- encoding: utf-8 -*-

require 'webgen/item_tracker'

module Webgen
  class ItemTracker

    # This class is used to track changes to the result of a node finder option set.
    #
    # Depending on whether the content or the meta info of the found nodes should be tracked, one
    # needs to provide the following item:
    #
    # [option_set, ref_node, :content]
    #   Tracks changes to the content of the found nodes.
    #
    # [option_set, ref_node, :meta_info]
    #   Tracks changes to the meta info of the found nodes.
    #
    class NodeFinderOptionSet

      def initialize(website) #:nodoc:
        @website = website
      end

      def item_id(option_set, ref_node, type) #:nodoc:
        [option_set, ref_node.alcn, type]
      end

      def item_data(option_set, ref_alcn, type) #:nodoc:
        nodes_to_alcn(@website.node_finder.find(option_set, @website.tree[ref_alcn]))
      end

      def changed?(iid, old_data) #:nodoc:
        option_set, ref_alcn, type = *iid
        nodes = @website.node_finder.find(option_set, @website.tree[ref_alcn])
        old_data != nodes_to_alcn(nodes) ||
          nodes.flatten.any? {|n| type == :content ? @website.item_tracker.node_changed?(n) : @website.item_tracker.item_changed?(:node_meta_info, n.alcn)}
      end

      def node_referenced?(iid, node_alcn) #:nodoc
        option_set, ref_alcn, type = *iid
        @website.node_finder.find(option_set, @website.tree[ref_alcn]).flatten.any? {|n| n.alcn == node_alcn}
      end

      def nodes_to_alcn(nodes) #:nodoc:
        nodes.map {|node, children| children.nil? ? node.alcn : [node.alcn, nodes_to_alcn(children)]}
      end

    end

  end
end
