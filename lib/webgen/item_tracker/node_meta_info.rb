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
    class NodeMetaInfo

      def initialize(website) #:nodoc:
        @website = website
      end

      def item_id(alcn, key = nil) #:nodoc:
        [alcn, key]
      end

      def item_data(alcn, key = nil) #:nodoc:
        mi = @website.tree[alcn].meta_info
        key.nil? ? mi.dup : mi[key].dup
      end

      def changed?(iid, old_data) #:nodoc:
        alcn, key = *iid
        @website.tree[alcn].nil? ||
          (key.nil? ? @website.tree[alcn].meta_info : @website.tree[alcn].meta_info[key]) != old_data
      end

      def node_referenced?(iid, node_alcn) #:nodoc
        iid.first == node_alcn
      end

    end

  end
end
