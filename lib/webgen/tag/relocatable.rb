# -*- encoding: utf-8 -*-

require 'uri'

module Webgen
  class Tag

    # Makes a path relative.
    #
    # For example, you normally include a stylesheet in a template. If you specify the path name of
    # the stylesheet directly, the reference to the stylesheet in the output file of a page file
    # that is not in the same directory as the template would be invalid.
    #
    # By using the relocatable tag you ensure that the path stays valid.
    module Relocatable

      # Return the relativized path for the path provided in the tag definition.
      def self.call(tag, body, context)
        path = context[:config]['tag.relocatable.path']
        result = ''
        begin
          result = (Webgen::Path.absolute?(path) ? path : resolve_path(path, context))
        rescue URI::InvalidURIError => e
          context.website.logger.warn do
            ["Could not parse path '#{path}' for tag.relocatable in <#{context.ref_node}>",
             e.message]
          end
        end
        result
      end

      # Resolve the path using the reference node and return the correct relative path from the
      # destination node.
      def self.resolve_path(path, context)
        fragment = ''

        if context[:config]['tag.relocatable.ignore_unknown_fragment']
          file, *fragments = path.split('#')
          fragment = '#' << fragments.join('#') unless fragments.empty?
          dest_node = context.ref_node.resolve(file, context.dest_node.lang, true)
          context.website.logger.vinfo do
            "Ignoring unknown fragment part of path '#{path}' for tag.relocatable in <#{context.ref_node}>"
          end if dest_node && fragment.length > 0
        else
          dest_node = context.ref_node.resolve(path, context.dest_node.lang, true)
        end

        if dest_node
          context.website.ext.item_tracker.add(context.dest_node, :node_meta_info, dest_node)
          context.dest_node.route_to(dest_node) + fragment
        else
          ''
        end
      end

    end

  end
end
