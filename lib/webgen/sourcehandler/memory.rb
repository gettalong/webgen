# -*- encoding: utf-8 -*-

module Webgen::SourceHandler

  # This source handler should be used for handling nodes that are created during the write
  # phase.
  class Memory

    include Webgen::WebsiteAccess
    include Base

    def initialize #:nodoc:
      website.blackboard.add_listener(:node_flagged) do |node, *flags|
        node.tree[node.node_info[:memory_source_alcn]].flag(:dirty) if node.node_info[:memory_source_alcn]
      end
    end

    # Create a node for the +path+. The +source_alcn+ specifies the node that creates this memory
    # node when written. You have two options for providing the content for this node: either you
    # set +data+ to a string (or a Webgen::Path::SourceIO object) or you provide a block which takes
    # the created node as argument and returns a string (or a Webgen::Path::SourceIO object).
    def create_node(path, source_alcn, data = nil)
      super(path) do |node|
        node.node_info[:memory_source_alcn] = source_alcn
        (@data ||= {})[node.alcn] = lambda { data || yield(node) }
      end
    end

    # Return the content of the memory +node+. If the memory node was not created in this webgen
    # run, it will be flagged for reinitialization (and therefore recreation).
    def content(node)
      if @data && @data[node.alcn]
        @data[node.alcn].call
      else
        node.flag(:reinit)
        nil
      end
    end

  end

end
