# -*- encoding: utf-8 -*-

require 'pathname'
require 'yaml'

module Webgen::SourceHandler

  # Handles meta information files which provide meta information for other files.
  class Metainfo

    include Base
    include Webgen::WebsiteAccess

    CKEY = [:metainfo, :nodes]

    # Upon creation the object registers itself as listener for some node hooks.
    def initialize
      website.blackboard.add_listener(:node_meta_info_changed?, method(:node_meta_info_changed?))
      website.blackboard.add_listener(:before_node_created, method(:before_node_created))
      website.blackboard.add_listener(:before_node_deleted, method(:before_node_deleted))
      website.blackboard.add_listener(:after_node_created, method(:after_node_created))
      self.nodes ||= []
    end

    # Create a meta info node from +parent+ and +path+.
    def create_node(parent, path)
      page = page_from_path(path)
      super(parent, path) do |node|
        [[:mi_paths, 'paths'], [:mi_alcn, 'alcn']].each do |mi_key, block_name|
          node.node_info[mi_key] = {}
          if page.blocks.has_key?(block_name) && (data = YAML::load(page.blocks[block_name].content))
            data.each do |key, value|
              key = Webgen::Common.absolute_path(key, parent.absolute_lcn)
              node.node_info[mi_key][key] = value
            end
          end
        end

        mark_all_matched_dirty(node, :no_old_data)

        website.cache.permanent[[:sh_metainfo_node_mi, node.absolute_lcn]] = {
          :mi_paths => node.node_info[:mi_paths],
          :mi_alcn => node.node_info[:mi_alcn]
        }

        self.nodes << node unless self.nodes.include?(node)
        self.nodes = self.nodes.sort_by {|n| n.absolute_lcn}
      end
    end

    def nodes #:nodoc:
      website.cache.permanent[CKEY]
    end

    def nodes=(val) #:nodoc:
      website.cache.permanent[CKEY] = val
    end

    #######
    private
    #######

    # Return +true+ if any meta information for +node+ provided by +mi_node+ has changed.
    def meta_info_changed?(mi_node, node, option = nil)
      cached = website.cache.permanent[[:sh_metainfo_node_mi, mi_node.absolute_lcn]]
      (mi_node.node_info[:mi_paths].any? do |pattern, mi|
         Webgen::Path.match(node.node_info[:creation_path], pattern) &&
           (option == :force || (!cached && option == :no_old_data) || mi != cached[:mi_paths][pattern])
       end || mi_node.node_info[:mi_alcn].any? do |pattern, mi|
         node =~ pattern && (option == :force || (!cached && option == :no_old_data) || mi != cached[:mi_alcn][pattern])
       end || (option == :no_old_data && cached &&
               ((cached[:mi_paths].keys - mi_node.node_info[:mi_paths].keys).any? do |p|
                 Webgen::Path.match(node.node_info[:creation_path], p)
                end || (cached[:mi_alcn].keys - mi_node.node_info[:mi_alcn].keys).any? do |p|
                  node =~ p
                end)
               )
       )
    end

    # Mark all nodes that are matched by a path or an alcn specifcation in the meta info node +node+
    # as dirty.
    def mark_all_matched_dirty(node, option = nil)
      node.tree.node_access[:alcn].each do |path, n|
        n.flag(:dirty_meta_info) if meta_info_changed?(node, n, option)
      end
    end

    # Update the meta info of matched path before a node is created.
    def before_node_created(parent, path)
      self.nodes.each do |node|
        node.node_info[:mi_paths].each do |pattern, mi|
          path.meta_info.update(mi) if Webgen::Path.match(path, pattern)
        end
      end
    end

    # Update the meta information of a matched alcn after the node has been created.
    def after_node_created(node)
      self.nodes.each do |n|
        n.node_info[:mi_alcn].each do |pattern, mi|
          node.meta_info.update(mi) if node =~ pattern
        end
      end
    end

    # Check if the +node+ has meta information from any meta info node and if so, if the meta info
    # node in question has changed.
    def node_meta_info_changed?(node)
      self.nodes.each do |n|
        if n.flagged?(:created) && meta_info_changed?(n, node)
          node.flag(:dirty_meta_info)
          return
        end
      end
    end

    # Delete the meta info node +node+ from the internal array.
    def before_node_deleted(node)
      return unless node.node_info[:processor] == self.class.name
      mark_all_matched_dirty(node, :force)
      website.cache.permanent.delete([:sh_metainfo_node_mi, node.absolute_lcn])
      self.nodes.delete(node)
    end

  end

end
