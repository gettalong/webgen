# -*- encoding: utf-8 -*-

module Webgen
  class Tag

    # Generates a list with all the languages of the page.
    module Langbar

      # Return a rendering of the list of all translations of the content node.
      def self.call(tag, body, context)
        context.website.ext.item_tracker.add(context.dest_node, :nodes,
                                             ['Webgen::Tag::Langbar', 'node_translations'],
                                             context.content_node.alcn, :meta_info)
        nodes = node_translations(context.website, context.content_node.alcn)

        if (context[:config]['tag.langbar.show_single_lang'] || nodes.length > 1) &&
            (template_node = resolve_template_node(context))
          context[:langnodes] = nodes.
            reject {|n| (context.content_node.lang == n.lang && !context[:config]['tag.langbar.show_own_lang'])}.
            sort {|a, b| a.lang <=> b.lang}
          context.render_block(:name => 'tag.langbar', :chain => [template_node, context.content_node])
        else
          ''
        end
      end

      # Return the template node for the langbar tag or +nil+ if it cannot be found.
      def self.resolve_template_node(context)
        path = context[:config]['tag.langbar.template']
        template_node = context.ref_node.resolve(path, context.dest_node.lang)
        if !template_node
          context.website.logger.error { "Could not resolve template path '#{path}' for tag 'langbar' in <#{context.ref_node}>" }
        end
        template_node
      end

      # Generate the list of node translations given the options.
      #
      # This method is invoked by Webgen::ItemTracker::NodeList to retrieve the translations nodes
      # when necessary.
      def self.node_translations(website, node_alcn)
        website.tree.translations(website.tree[node_alcn])
      end

    end

  end
end
