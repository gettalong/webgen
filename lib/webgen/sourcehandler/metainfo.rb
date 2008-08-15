require 'pathname'
require 'yaml'
require 'webgen/sourcehandler/base'
require 'webgen/websiteaccess'

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
      self.nodes ||= Set.new
    end

    # Create a meta info node from +parent+ and +path+.
    def create_node(parent, path)
      page = page_from_path(path)
      super(parent, path) do |node|
        [[:mi_paths, 'paths'], [:mi_alcn, 'alcn']].each do |mi_key, block_name|
          node.node_info[mi_key] = {}
          YAML::load(page.blocks[block_name].content).each do |key, value|
            key = Pathname.new(key =~ /^\// ? key : File.join(parent.absolute_lcn, key)).cleanpath.to_s
            key.chomp('/') unless key == '/'
            node.node_info[mi_key][key] = value
          end if page.blocks.has_key?(block_name)
        end
        website.cache[[:sh_metainfo_node_mi, node.absolute_lcn]] = {
          :mi_paths => node.node_info[:mi_paths],
          :mi_alcn => node.node_info[:mi_alcn]
        }

        mark_all_matched_dirty(node)

        self.nodes << node
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
    def meta_info_changed?(mi_node, node, use_cache = true)
      use_cache = false if !website.cache.old_data[[:sh_metainfo_node_mi, mi_node.absolute_lcn]]
      cached = website.cache[[:sh_metainfo_node_mi, mi_node.absolute_lcn]]
      path = website.blackboard.invoke(:source_paths)[node.node_info[:src]]
      (mi_node.node_info[:mi_paths].any? {|pattern, mi| path =~ pattern && (!use_cache || mi != cached[:mi_paths][pattern])} ||
       mi_node.node_info[:mi_alcn].any? {|pattern, mi| node =~ pattern && (!use_cache || mi != cached[:mi_alcn][pattern])})
    end

    # Mark all nodes that are matched by a path or an alcn specifcation in the meta info node +node+
    # as dirty.
    def mark_all_matched_dirty(node, use_cache = true)
      node.tree.node_access[:alcn].each do |path, n|
        n.dirty_meta_info = true if meta_info_changed?(node, n, use_cache)
      end
    end

    # Update the meta info of matched path before a node is created.
    def before_node_created(parent, path)
      self.nodes.each do |node|
        node.node_info[:mi_paths].each do |pattern, mi|
          path.meta_info.update(mi) if path =~ pattern
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
      return if self.nodes.include?(node)
      self.nodes.each do |n|
        if n.created && meta_info_changed?(n, node)
          node.dirty_meta_info = true
          return
        end
      end
    end

    # Delete the meta info node +node+ from the internal array.
    def before_node_deleted(node)
      return unless node.node_info[:processor] == self.class.name
      mark_all_matched_dirty(node, false) if !website.blackboard.invoke(:source_paths).include?(node.node_info[:src])
      self.nodes.delete(node)
    end

  end

end
