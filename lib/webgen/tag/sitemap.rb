require 'webgen/websiteaccess'
require 'webgen/tag'

module Webgen::Tag

  # Generates a sitemap. The sitemap contains the hierarchy of all pages on the web site.
  class Sitemap

    include Base
    include Webgen::WebsiteAccess

    def initialize #:nodoc:
      website.blackboard.add_listener(:node_changed?, method(:node_changed?))
    end

    # Create the sitemap.
    def call(tag, body, context)
      tree = sitemap_tree(nil, context.content_node.tree.root, context.content_node.lang).sort!
      (context.dest_node.node_info[:tag_sitemap] ||= {})[[@params.to_a.sort, context.content_node.lang]] = tree.to_lcn_list
      (tree.children.empty? ? '' : output_sitemap(tree, context))
    end

    # Return the sitemap tree for the language +lang+.
    def sitemap_tree(parent, node, lang)
      mnode = Menu::MenuNode.new(parent, node)
      node.children.select do |n|
        n.is_directory? || ((param('tag.sitemap.used_kinds').empty? || param('tag.sitemap.used_kinds').include?(n['kind'])) &&
                            (param('tag.sitemap.any_lang') || n.lang.nil? || n.lang == lang) &&
                            (!param('tag.sitemap.honor_in_menu') || n['in_menu']) &&
                            (parent.nil? || node.routing_node(lang) != n))
      end.each do |n|
        sub_node = sitemap_tree(mnode, n, lang)
        mnode.children << sub_node unless sub_node.nil?
      end
      (mnode.children.empty? && mnode.node.is_directory? && !parent.nil? ? nil : mnode)
    end

    #######
    private
    #######

    # Check if the menus for +node+ have changed.
    def node_changed?(node)
      return if !node.node_info[:tag_sitemap]

      node.node_info[:tag_sitemap].each do |(params, lang), cached_tree|
        set_params(params.to_hash)
        tree = sitemap_tree(nil, node.tree.root, lang).to_lcn_list
        set_params({})

        if (tree != cached_tree) ||
            (tree.flatten.any? do |alcn|
               (n = node.tree[alcn]) && (r = n.routing_node(lang)) && r.meta_info_changed?
             end)
          node.dirty = true
          break
        end
      end
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
