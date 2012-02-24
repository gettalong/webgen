# -*- encoding: utf-8 -*-

require 'webgen/item_tracker'

module Webgen
  class ItemTracker

    # This class is used to track changed node content via the +modified_at+ meta information.
    #
    # The item for this tracker is the alcn of the node.
    class NodeContent

      def initialize(website) #:nodoc:
        @website = website
      end

      def item_id(alcn) #:nodoc:
        alcn
      end

      def item_data(alcn) #:nodoc:
        @website.tree[alcn]['modified_at']
      end

      def changed?(alcn, old_data) #:nodoc:
        @website.tree[alcn].nil? || @website.tree[alcn]['modified_at'] != old_data
      end

      def node_referenced?(alcn, node_alcn) #:nodoc:
        alcn == node_alcn
      end

    end

  end
end
