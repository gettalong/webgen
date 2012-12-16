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

      # Upon creation the path handler registers itself as listener for the :apply_meta_info_to_path and
      # :after_node_created hooks so that it can apply the meta information.
      def initialize(website)
        super
        @website.blackboard.add_listener(:apply_meta_info_to_path, &method(:apply_meta_info_to_path))
        @website.blackboard.add_listener(:after_node_created, &method(:after_node_created))
        @paths = []
        @alcns = []
      end

      # Create a meta info node from +path+.
      def create_nodes(path, blocks)
        @paths += add_data(path, blocks['paths'], 'paths')
        entries = add_data(path, blocks['alcn'], 'alcn')
        @alcns += entries
        update_existing_nodes(entries)

        nil
      end

      #######
      private
      #######

      # Add the data from the given page block to the hash.
      def add_data(path, content, block_name)
        entries = []
        if content && (data = YAML::load(content))
          data.each do |(*keys), value|
            value = Marshal.dump(value)
            keys.each {|key| entries << [Webgen::Path.append(path.parent_path, key), value]}
          end
        end
        entries
      rescue Exception => e
        raise Webgen::NodeCreationError.new("Could not parse block '#{block_name}': #{e.message}", "path_handler.meta_info")
      end

      # Update already existing nodes with meta information from the given meta info node.
      def update_existing_nodes(entries)
        @website.tree.node_access[:alcn].each do |alcn, node|
          entries.each do |pattern, mi|
            node.meta_info.update(Marshal.load(mi)) if Webgen::Path.matches_pattern?(alcn, pattern)
          end
        end
      end

      # Update the meta info of matched path before a node is created.
      def apply_meta_info_to_path(path)
        hash = {}
        @paths.each do |pattern, mi|
          hash.merge!(Marshal.load(mi)) if Webgen::Path.matches_pattern?(path, pattern)
        end
        path.meta_info.replace(hash.merge!(path.meta_info)) if hash.length > 0
      end

      # Update the meta information of a matched alcn after the node has been created.
      def after_node_created(node)
        @alcns.each do |pattern, mi|
          node.meta_info.update(Marshal.load(mi)) if Webgen::Path.matches_pattern?(node.alcn, pattern)
        end
      end

    end

  end
end
