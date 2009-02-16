# -*- encoding: utf-8 -*-

module Webgen::Tag

  # Generates a list with all the languages of the page.
  class Langbar

    include Webgen::Tag::Base
    include Webgen::WebsiteAccess

    def initialize #:nodoc:
      website.blackboard.add_listener(:node_changed?, method(:node_changed?))
    end

    # Return a list of all translations of the content page.
    def call(tag, body, context)
      lang_nodes = all_lang_nodes(context.content_node)
      (context.dest_node.node_info[:tag_langbar_data] ||= {})[context.content_node.absolute_cn] = lang_nodes.map {|n| n.absolute_lcn}
      result = lang_nodes.
        reject {|n| (context.content_node.lang == n.lang && !param('tag.langbar.show_own_lang'))}.
        sort {|a, b| a.lang <=> b.lang}.
        collect {|n| context.dest_node.link_to(n, :link_text => (param('tag.langbar.lang_names')[n.lang] || n.lang), :lang => n.lang)}.
        join(param('tag.langbar.separator'))
      (param('tag.langbar.show_single_lang') || lang_nodes.length > 1 ? result : "")
    end

    #######
    private
    #######

    # Return all nodes with the same absolute cn as +node+.
    def all_lang_nodes(node)
      node.tree.node_access[:acn][node.absolute_cn]
    end

    # Check if the langbar tag for +node+ changed.
    def node_changed?(node)
      return unless (cdata = node.node_info[:tag_langbar_data])
      cdata.each do |acn, clang_nodes|
        lang_nodes = all_lang_nodes(node.tree[acn, :acn]) rescue nil
        if !lang_nodes || lang_nodes.length != clang_nodes.length ||
            lang_nodes.any? {|n| n.meta_info_changed?}
          node.flag(:dirty)
          break
        end
      end
    end

  end

end
