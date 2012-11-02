# -*- encoding: utf-8 -*-

require 'uri'
require 'yaml'
require 'webgen/path_handler/base'
require 'webgen/path_handler/page_utils'

module Webgen
  class PathHandler

    # Handles files which contain specifications for "virtual" nodes, ie. nodes that don't have real
    # source paths.
    #
    # This can be used, for example, to provide multiple links to the same node or links to external
    # URLs.
    class Virtual

      include Base
      include PageUtils

      # Create all virtual nodes which are specified in +path+.
      def create_nodes(path, blocks)
        nodes = []
        if path.meta_info.delete(:virtual)
          nodes << create_node(path)
        else
          read_entries(blocks) do |key, meta_info|
            meta_info['modified_at'] = path.meta_info['modified_at']
            meta_info['no_output'] = true

            key = Webgen::Path.append(path.parent_path, key)
            parent_path = create_directories(File.dirname(key), 'modified_at' => meta_info['modified_at'])

            dest_path = meta_info.delete('dest_path') || key
            dest_path = (URI::parse(dest_path).absolute? || dest_path =~ /^\// ?
                         dest_path : File.join(parent_path, dest_path))
            meta_info['dest_path'] = dest_path
            entry_path = Webgen::Path.new(key, meta_info)

            if key =~ /\/$/
              entry_path['handler'] = 'directory'
              nodes << @website.ext.path_handler.create_secondary_nodes(entry_path)
            else
              entry_path[:virtual] = true
              entry_path['handler'] = 'virtual'
              nodes << @website.ext.path_handler.create_secondary_nodes(entry_path)
            end
          end
        end
        nodes.flatten.compact.each do |node|
          node.node_info[:path] = path
        end
      end

      #######
      private
      #######

      # Read all entries from all blocks and yield the found path as well as the meta info hash for
      # each entry.
      def read_entries(blocks)
        blocks.each do |name, content|
          YAML::load(content).each do |key, meta_info|
            yield(key, meta_info || {})
          end
        end
      end

      # Create the needed parent directories for a virtual node.
      def create_directories(directory, mi)
        mi.merge!('no_output' => true, 'handler' => 'directory')
        directory.sub(/^\//, '').split('/').inject('/') do |parent_path, dir|
          parent_path = File.join(parent_path, dir) + '/'
          path = Webgen::Path.new(parent_path, mi)
          if !@website.tree[path.alcn]
            @website.ext.path_handler.create_secondary_nodes(path)
          end
          parent_path
        end
      end

    end

  end
end
