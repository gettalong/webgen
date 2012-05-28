# -*- encoding: utf-8 -*-

require 'webgen/item_tracker'

module Webgen
  class ItemTracker

    # This class is used to track unresolved absolute node paths.
    #
    # The item for this tracker is the unresolved absolute node path and, optionally, a language.
    class MissingNode

      def initialize(website) #:nodoc:
        @website = website
        @at_least_one_node_created = true
        @stop_reporting = false

        @website.blackboard.add_listener(:after_node_created, self) do
          @at_least_one_node_created = true
        end
        @website.blackboard.add_listener(:after_all_nodes_written, self) do
          if @at_least_one_node_created
            @at_least_one_node_created = false
          else
            @stop_reporting = true
          end
        end
        @website.blackboard.add_listener(:website_generated, self) do
          @at_least_one_node_created = true
          @stop_reporting = false
        end
      end

      def item_id(path, lang = nil) #:nodoc:
        [path, lang]
      end

      def item_data(path, lang) #:nodoc:
        @website.tree.resolve_node(path, lang).nil?
      end

      def changed?(iid, old_data) #:nodoc:
        return false if @stop_reporting
        missing = item_data(*iid)
        missing || missing != old_data
      end

      def node_referenced?(iid, node_alcn) #:nodoc:
        iid.first == node_alcn
      end

    end

  end
end
