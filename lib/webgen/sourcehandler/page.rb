module Webgen::SourceHandler

  # Source handler for handling content files in Webgen Page Format.
  class Page

    include Webgen::WebsiteAccess
    include Base

    def initialize #:nodoc:
      website.blackboard.add_listener(:node_meta_info_changed?, method(:meta_info_changed?))
    end

    # Create a page file from +parent+ and +path+.
    def create_node(parent, path)
      page = page_from_path(path)
      path.meta_info['lang'] ||= website.config['website.lang']
      path.ext = 'html' if path.ext == 'page'

      super(parent, path) do |node|
        website.cache[[:sh_page_node_mi, node.absolute_lcn]] = node.meta_info.dup

        node.node_info[:page] = page
        tmp_logger = website.logger
        website.logger = nil    # disabling logging whiling creating fragment nodes

        website.cache.permanent[:page_sections] ||= {}
        sections = if path.changed? || !website.cache.permanent[:page_sections][node.absolute_lcn]
                     website.blackboard.invoke(:parse_html_headers, render_node(node, 'content', []))
                   else
                     website.cache.permanent[:page_sections][node.absolute_lcn]
                   end
        website.cache.permanent[:page_sections][node.absolute_lcn] = sections
        website.blackboard.invoke(:create_fragment_nodes,
                                  sections,
                                  node, website.blackboard.invoke(:source_paths)[path.path],
                                  node.meta_info['fragments_in_menu'])
        website.logger = tmp_logger
      end
    end

    # Render the block called +block_name+ of the given +node+. The parameter +templates+ is set to
    # the default template chain for the given +node+ but you can assign a custom template chain (an
    # array of template nodes) if need arises. Return +nil+ if an error occurred.
    def render_node(node, block_name = 'content', templates = website.blackboard.invoke(:templates_for_node, node))
      chain = [templates, node].flatten

      if chain.first.node_info[:page].blocks.has_key?(block_name)
        node.node_info[:used_nodes] << chain.first.absolute_lcn
        context = chain.first.node_info[:page].blocks[block_name].render(Webgen::ContentProcessor::Context.new(:chain => chain))
        context.content
      else
        raise "Error rendering <#{node.absolute_lcn}>: no block named '#{block_name}' in <#{chain.first.absolute_lcn}>"
      end
    end
    alias_method :content, :render_node

    #######
    private
    #######

    # Checks if the meta information provided by the file in Webgen Page Format changed.
    def meta_info_changed?(node)
      return if !node.created || node.node_info[:processor] != self.class.name
      ckey = [:sh_page_node_mi, node.absolute_lcn]
      old_mi = website.cache.old_data[ckey]
      old_mi.delete('modified_at') if old_mi
      new_mi = website.cache.new_data[ckey]
      new_mi.delete('modified_at')
      node.dirty_meta_info = true if old_mi != new_mi
    end

  end

end
