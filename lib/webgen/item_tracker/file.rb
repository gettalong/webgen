# -*- encoding: utf-8 -*-

require 'webgen/item_tracker'

module Webgen
  class ItemTracker

    # This class is used to track changes to a file.
    #
    # The item for this tracker is the name of the file.
    class File

      def initialize(website) #:nodoc:
        @website = website
      end

      def item_id(filename) #:nodoc:
        filename
      end

      def item_data(filename) #:nodoc:
        ::File.mtime(filename)
      end

      def changed?(filename, old_mtime) #:nodoc:
        ::File.mtime(filename) > old_mtime
      end

      def node_referenced?(filename) #:nodoc
        false
      end

    end

  end
end
