# -*- encoding: utf-8 -*-

module Webgen::SourceHandler

  # Source handler for handling content files in Webgen Page Format.
  class Page

    include Webgen::WebsiteAccess
    include Base

    def initialize #:nodoc:
      website.blackboard.add_listener(:node_meta_info_changed?, method(:meta_info_changed?))
    end

    # Create a page file from +path+.
    def create_node(path)
      page = page_from_path(path)
      path.meta_info['lang'] ||= website.config['website.lang']
      path.ext = 'html' if path.ext == 'page'

      super(path) do |node|
        node.node_info[:sh_page_node_mi] = Webgen::Page.meta_info_from_data(path.io.data)
        node.node_info[:page] = page
      end
    end

    # Render the block called +block_name+ of the given +node+. The parameter +templates+ is set to
    # the default template chain for the given +node+ but you can assign a custom template chain (an
    # array of template nodes) if need arises. Return +nil+ if an error occurred.
    def render_node(node, block_name = 'content', templates = website.blackboard.invoke(:templates_for_node, node))
      chain = [templates, node].flatten

      if chain.first.node_info[:page].blocks.has_key?(block_name)
        node.node_info[:used_nodes] << chain.first.alcn
        context = chain.first.node_info[:page].blocks[block_name].render(Webgen::Context.new(:chain => chain))
        context.content
      else
        raise Webgen::RenderError.new("No block named '#{block_name}'",
                                      self.class.name, node.alcn, chain.first.alcn)
      end
    end
    alias_method :content, :render_node

    #######
    private
    #######

    # Checks if the meta information provided by the file in Webgen Page Format changed.
    def meta_info_changed?(node)
      path = website.blackboard.invoke(:source_paths)[node.node_info[:src]]
      return if node.node_info[:processor] != self.class.name || (path && !path.changed?)

      if !path
        node.flag(:dirty_meta_info)
      else
        old_mi = node.node_info[:sh_page_node_mi]
        new_mi = Webgen::Page.meta_info_from_data(path.io.data)
        node.flag(:dirty_meta_info) if old_mi && old_mi != new_mi
      end
    end

  end

end
