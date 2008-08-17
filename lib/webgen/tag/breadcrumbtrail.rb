require 'webgen/websiteaccess'
require 'webgen/tag'

module Webgen::Tag

  # Generates a breadcrumb trail for the page. This is especially useful when pages are in deep
  # hierarchies of directories.
  class BreadcrumbTrail

    include Webgen::WebsiteAccess
    include Base

    def initialize #:nodoc:
      website.blackboard.add_listener(:node_changed?, method(:node_changed?))
    end

    # Create the breadcrumb trail.
    def call(tag, body, context)
      out = breadcrumb_trail_list(context.content_node)
      (context.dest_node.node_info[:tag_breadcrumb_trail] ||= {})[[@params, context.content_node.absolute_lcn]] = out.map {|n| n.absolute_lcn}
      out = out.map {|n| context.dest_node.link_to(n, :lang => context.content_node.lang) }.
        join(param('tag.breadcrumbtrail.separator'))
      log(:debug) { "Breadcrumb trail for <#{context.content_node.absolute_lcn}>: #{out}" }
      out
    end

    #######
    private
    #######

    # Return the list of nodes that make up the breadcrumb trail of +node+ according to the current
    # parameters.
    def breadcrumb_trail_list(node)
      list = []
      omit_index_path = if node.meta_info.has_key?('omit_index_path')
                          node['omit_index_path']
                        else
                          param('tag.breadcrumbtrail.omit_index_path')
                        end
      omit_index_path = omit_index_path && node.parent.routing_node(node.lang) == node

      node = node.parent if omit_index_path

      until node == node.tree.dummy_root
        list.unshift(node)
        node = node.parent
      end
      list[param('tag.breadcrumbtrail.start_level')..param('tag.breadcrumbtrail.end_level')].to_a
    end

    # Check if the breadcrumb trails for +node+ have changed.
    def node_changed?(node)
      return if !node.node_info[:tag_breadcrumb_trail]

      node.node_info[:tag_breadcrumb_trail].each do |(params, cn_alcn), cached_list|
        cn = node.tree[cn_alcn]
        set_params(params)
        list = breadcrumb_trail_list(cn)
        set_params({})

        if (list.map {|n| n.absolute_lcn} != cached_list) ||
            list.any? {|n| (r = n.routing_node(cn.lang)) && r != node && r.meta_info_changed?}
          node.dirty = true
          break
        end
      end
    end

  end

end
