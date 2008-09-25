module Webgen::Tag

  # Generates a sitemap. The sitemap contains the hierarchy of all pages on the web site.
  class Sitemap

    include Base
    include Webgen::WebsiteAccess

    # Create the sitemap.
    def call(tag, body, context)
      tree = website.blackboard.invoke(:create_sitemap, context.dest_node, context.content_node.lang, @params)
      (tree.children.empty? ? '' : output_sitemap(tree, context))
    end

    #######
    private
    #######

    # The modified tag base to support the easy specification of common.sitemap.* options.
    def tag_config_base
      'common.sitemap'
    end

    # Create the HTML representation of the sitemap nodes in +tree+ in respect to +context+.
    def output_sitemap(tree, context)
      out = "<ul>"
      tree.children.each do |child|
        sub = (child.children.length > 0 ? output_sitemap(child, context) : '')
        out << "<li>" + context.dest_node.link_to(child.node, :lang => child.node.lang || context.content_node.lang)
        out << sub
        out << "</li>"
      end
      out << "</ul>"
      out
    end

  end

end
