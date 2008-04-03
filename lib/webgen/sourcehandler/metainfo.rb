require 'yaml'

module Webgen::SourceHandler

  class Metainfo

    include Base
    include Webgen::WebsiteAccess

    def initialize
      website.blackboard.add_listener(:node_changed?, method(:node_changed?))
      website.blackboard.add_listener(:before_node_created, method(:assign_meta_info))
      website.blackboard.add_listener(:node_deleted, method(:node_deleted))
      @nodes = Set.new
    end

    def create_node(parent, path)
      super(parent, path) do |node|
        #TODO: Adjust paths to be absolute ones
        node.node_info[:data] = YAML::load(path.io.read)

        node.node_info[:data].each do |path, mi|
          (n = parent.tree.node_access[path]) && n.dirty = true
        end
        @nodes << node
      end
    end

    def marshal_dump
      @nodes
    end

    def marshal_load(obj)
      initialize
      @nodes = obj
    end

    private

    def assign_meta_info(parent, path)
      @nodes.sort_by{|a| a.absolute_lcn}.each do |node|
        path.meta_info.update(node.node_info[:data][path.path] || {})
      end
    end

    def node_changed?(node)
      @nodes.each do |n|
        if n.node_info[:data].has_key?(node.absolute_lcn) && n.changed?
          node.dirty = true
          return
        end
      end
    end

    def node_deleted(node)
      @nodes.delete(node)
    end

  end

end
