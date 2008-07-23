require 'webgen/tag'

module Webgen::Tag

  # Generates a breadcrumb trail for the page. This is especially useful when pages are in deep
  # hierarchies of directories.
  class BreadcrumbTrail

    include Webgen::Tag::Base

    # Create the breadcrumb trail.
    def call(tag, body, context)
      out = []
      node = context.content_node

      omit_index_path = if node.meta_info.has_key?('omit_index_path')
                          node['omit_index_path']
                        else
                          param('tag.breadcrumbtrail.omit_index_path')
                        end
      omit_index_path = omit_index_path && node.parent.routing_node(node.lang) == node

      node = node.parent if omit_index_path

      until node == node.tree.dummy_root
        context.dest_node.node_info[:used_nodes] << node.routing_node(context.dest_node.lang).absolute_lcn
        context.dest_node.node_info[:used_nodes] << node.absolute_lcn
        out.push(context.dest_node.link_to(node.in_lang(context.content_node.lang)))
        node = node.parent
      end
      out[0] = '' if param('tag.breadcrumbtrail.omit_last') && !omit_index_path
      out = out.reverse.join(param('tag.breadcrumbtrail.separator'))
      log(:debug) { "Breadcrumb trail for <#{context.dest_node.absolute_lcn}>: #{out}" }
      out
    end

  end

end
