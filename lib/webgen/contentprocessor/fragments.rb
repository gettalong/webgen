module Webgen::ContentProcessor

  # Uses the HTML headers h1, h2, ..., h6 to generate nested fragment nodes.
  class Fragments

    include Webgen::WebsiteAccess

    # Generate the nested fragment nodes from <tt>context.content</tt> under
    # <tt>content.content_node</tt> but only if there is no associated <tt>:block</tt> data in
    # +context+ or the block is named +content+.
    def call(context)
      if !context[:block] || context[:block].name == 'content'
        sections = website.blackboard.invoke(:parse_html_headers, context.content)
        website.blackboard.invoke(:create_fragment_nodes, sections, context.content_node,
                                  website.blackboard.invoke(:source_paths)[context.content_node.node_info[:src]],
                                  context.content_node.meta_info['fragments_in_menu'])
      end
      context
    end

  end

end
