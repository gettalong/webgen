require 'webgen/websiteaccess'
require 'webgen/loggable'
require 'webgen/page'

module Webgen::SourceHandler

  # Source handler for handling content files in Webgen Page Format.
  class Page

    include Webgen::WebsiteAccess
    include Webgen::Loggable
    include Base

    def create_node(parent, path)
      begin
        page = Webgen::Page.from_data(path.io.data, path.meta_info)
      rescue Webgen::WebgenPageFormatError => e
        raise "Error reading source path <#{path}>: #{e.message}"
      end
      path.meta_info = page.meta_info
      path.meta_info['lang'] ||= website.config['website.lang']
      path.ext = 'html' if path.ext == 'page'

      super(parent, path) do |node|
        node.node_info[:page] = page
        website.blackboard.invoke(:create_fragment_nodes,
                                  website.blackboard.invoke(:parse_html_headers, render_node(node, 'content', [])),
                                  node, node.meta_info['fragments_in_menu'])
      end
    end

    # Renders the block called +block_name+ of the given +node+. The parameter +templates+ is set to
    # the default template chain for the given +node+ but you can assign a custom template chain (an
    # array of template nodes) if need arises. Returns +nil+ if an error occurred.
    def render_node(node, block_name = 'content', templates = website.blackboard.invoke(:templates_for_node, node))
      chain = [templates, node].flatten

      if chain.first.node_info[:page].blocks.has_key?(block_name)
        context = chain.first.node_info[:page].blocks[block_name].render(Webgen::ContentProcessor::Context.new(:chain => chain))
        context.content
      else
        raise "Error rendering <#{node.absolute_lcn}>: no block named '#{block_name}' in <#{chain.first.absolute_lcn}>"
      end
    end
    alias_method :content, :render_node

  end

end
