# -*- encoding: utf-8 -*-

require 'webgen/item_tracker'

module Webgen
  class ItemTracker

    # This class is used to track changes to a node's meta information.
    #
    # Depending on what should be tracked, one needs to provide the following item:
    #
    # [node_alcn, nil]
    #   Tracks changes to the whole meta information of the node, i.e. if any meta information value
    #   changes, a change is detected.
    #
    # [node_alcn, key]
    #   Tracks changes to a specific meta information key of the node.
    #
    # Here are some examples:
    #
    #   website.ext.item_tracker.add(some_node, :node_meta_info, my_node.alcn) # first case
    #   website.ext.item_tracker.add(some_node, :node_meta_info, my_node.alcn, 'title') # second case
    #
    class NodeMetaInfo

      CONTENT_MODIFICATION_KEY = 'modified_at'

      def initialize(website) #:nodoc:
        @website = website
      end

      def item_id(alcn, key = nil) #:nodoc:
        [alcn, key]
      end

      def item_data(alcn, key = nil) #:nodoc:
        mi = @website.tree[alcn].meta_info
        key.nil? ? (mi = mi.dup; mi.delete(CONTENT_MODIFICATION_KEY); mi) : mi[key].dup
      end

      def item_changed?(iid, old_data) #:nodoc:
        alcn, key = *iid
        @website.tree[alcn].nil? || item_data(alcn, key) != old_data
      end

      def referenced_nodes(iid, mi) #:nodoc:
        [iid.first]
      end

    end

  end
end
