require 'yaml'

module Webgen::SourceHandler

  class Metainfo

    include Base
    include Webgen::WebsiteAccess

    CKEY = [:metainfo, :nodes]

    def initialize
      website.blackboard.add_listener(:node_changed?, method(:node_changed?))
      website.blackboard.add_listener(:before_node_created, method(:before_node_created))
      website.blackboard.add_listener(:before_node_deleted, method(:before_node_deleted))
      self.nodes ||= Set.new
    end

    def create_node(parent, path)
      super(parent, path) do |node|
        node.node_info[:data] = {}
        YAML::load(path.io.read).each do |key, value|
          key = File.expand_path(key =~ /^\// ? key : parent.absolute_lcn + key)
          node.node_info[:data][key] = value
        end

        mark_all_matched_dirty(node)

        self.nodes << node
        self.nodes = self.nodes.sort_by {|n| n.absolute_lcn}
      end
    end

    def nodes; website.cache.permanent[CKEY]; end
    def nodes=(val); website.cache.permanent[CKEY] = val; end

    private

    def mark_all_matched_dirty(node)
      source_paths = website.blackboard.invoke(:source_paths)
      node.tree.node_access[:alcn].each do |path, n|
        n.dirty = true if node.node_info[:data].any? {|pattern, mi| source_paths[n.node_info[:src]] =~ pattern }
      end
    end

    def before_node_created(parent, path)
      self.nodes.each do |node|
        node.node_info[:data].each do |pattern, mi|
          path.meta_info.update(mi) if path =~ pattern
        end
      end
    end

    def node_changed?(node)
      path = website.blackboard.invoke(:source_paths)[node.node_info[:src]]
      self.nodes.each do |n|
        if n.node_info[:data].any? {|pattern,mi| path =~ pattern} && n.changed?
          node.dirty = true
          return
        end
      end
    end

    def before_node_deleted(node)
      return unless node.node_info[:processor] == self.class.name
      mark_all_matched_dirty(node)
      self.nodes.delete(node)
    end

  end

end
