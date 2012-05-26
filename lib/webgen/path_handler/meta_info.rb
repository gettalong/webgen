# -*- encoding: utf-8 -*-

require 'pathname'
require 'set'
require 'yaml'
require 'webgen/path_handler/base'
require 'webgen/path_handler/page_utils'

module Webgen
  class PathHandler

    # Handles meta information paths which provide meta information for other paths.
    class MetaInfo

      include Base
      include PageUtils

      # Upon creation the object registers itself as listener for some node hooks.
      def initialize(website)
        super
        @website.blackboard.add_listener(:before_node_created, &method(:before_node_created))
        @website.blackboard.add_listener(:after_node_created, &method(:after_node_created))
        @nodes = []
      end

      # Create a meta info node from +path+.
      def create_nodes(path, blocks)
        create_node(path) do |node|
          node.node_info[:mi_paths] = {}
          node.node_info[:mi_alcn] = {}
          add_data(blocks['paths'], 'paths', node)
          add_data(blocks['alcn'], 'alcn', node)
          update_existing_nodes(node)
          @nodes << node
        end
      end

      #######
      private
      #######

      # Add the data from the given page block to the hash.
      def add_data(content, block_name, node)
        if content && (data = YAML::load(content))
          mi_key = (block_name == 'paths' ? :mi_paths : :mi_alcn)
          data.each do |key, value|
            key = Webgen::Path.append(node.parent.alcn, key)
            node.node_info[mi_key][key] = value
          end
        end
      rescue Exception => e
        raise Webgen::NodeCreationError.new("Could not parse block '#{block_name}': #{e.message}", self.class.name)
      end

      # Update already existing nodes with meta information from the given meta info node.
      def update_existing_nodes(mi_node)
        @website.tree.node_access[:alcn].each do |alcn, node|
          mi_node.node_info[:mi_alcn].each do |pattern, mi|
            node.meta_info.update(mi) if Webgen::Path.matches_pattern?(alcn, pattern)
          end
        end
      end

      # Update the meta info of matched path before a node is created.
      def before_node_created(path)
        @nodes.each do |mi_node|
          mi_node.node_info[:mi_paths].each do |pattern, mi|
            path.meta_info.update(mi) if Webgen::Path.matches_pattern?(path, pattern)
          end
        end
      end

      # Update the meta information of a matched alcn after the node has been created.
      def after_node_created(node)
        @nodes.each do |mi_node|
          mi_node.node_info[:mi_alcn].each do |pattern, mi|
            node.meta_info.update(mi) if Webgen::Path.matches_pattern?(node.alcn, pattern)
          end
        end
      end

    end

  end
end
