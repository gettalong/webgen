require 'webgen/tag'

module Webgen::Tag

  # Generates a list with all the languages of the page.
  class Langbar

    include Webgen::Tag::Base

    # Return a list of all translations of the content page.
    def call(tag, body, context)
      lang_nodes = context.content_node.tree.node_access[:acn][context.content_node.absolute_cn]
      nr_langs = lang_nodes.length
      result = lang_nodes.
        reject {|n| (context.content_node.lang == n.lang && !param('tag.langbar.show_own_lang')) }.
        sort {|a, b| a.lang <=> b.lang}.
        collect {|n| context.dest_node.link_to(n, :link_text => n.lang)}.
        join(param('tag.langbar.separator'))
      (param('tag.langbar.show_single_lang') || nr_langs > 1 ? result : "")
    end

  end

end
