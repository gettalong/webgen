# -*- encoding: utf-8 -*-

require 'yaml'
require 'webgen/error'

module Webgen

  module Misc

    # This extension creates dummy directory index paths for directories where the proxy_path meta
    # information does not point to a node whose lcn matches a directory index path name.
    class DummyIndex

      def initialize(website) #:nodoc:
        @website = website

        @website.blackboard.add_listener(:website_initialized) do
          if @website.config['misc.dummy_index.enabled'] && @website.config['misc.dummy_index.directory_indexes'].length > 0
            @website.blackboard.add_listener(:website_generated, &method(:create_dummy_indexes))
          end
        end
      end

      # Create the dummy index paths at the destination.
      def create_dummy_indexes
        indexes = @website.config['misc.dummy_index.directory_indexes']
        @website.tree.node_access[:alcn].each do |_, node|
          next if !node.is_directory? || !directory_exists?(node) || directory_index_exists?(node, indexes)

          route = node.route_to(node)
          route = node['proxy_path'].to_s if route == File.basename(node.dest_path)
          index_path = node.dest_path + indexes.first

          next if route == '' || indexes.any? {|index| index == route} ||
            (cache[node.alcn] == [indexes.first, route] && @website.ext.destination.exists?(index_path))

          @website.logger.info do
            "[#{@website.ext.destination.exists?(index_path) ? 'update' : 'create'}] <#{index_path}> (dummy directory path pointing to #{route})"
          end
          cache[node.alcn] = [indexes.first, route]
          @website.ext.destination.write(index_path, dummy_index_content(route))
        end
      end
      protected :create_dummy_indexes

      # Does the node directory exist at the destination?
      def directory_exists?(node)
        @website.ext.destination.exists?(node.dest_path)
      end
      protected :directory_exists?

      # Is there any node with a destination path matching any of the directory index paths?
      def directory_index_exists?(node, indexes) #:nodoc:
        indexes.any? {|index| @website.tree.node(node.dest_path + index, :dest_path)}
      end
      protected :directory_index_exists?

      # Return the dummy index path content for redirecting to +url+.
      def dummy_index_content(url)
        <<EOF
<!DOCTYPE html><html><head><title>Redirect</title><meta charset="UTF-8" />
<meta http-equiv="Refresh" content="0; url=#{url}" />
</head><body></body></html>
EOF
      end
      protected :dummy_index_content

      # Return the cache used by this extension.
      def cache
        @website.cache['misc.dummy_index.data'] ||= {}
      end
      protected :cache

    end

  end

end
