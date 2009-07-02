# -*- encoding: utf-8 -*-

require 'uri'

module Webgen::Tag

  # Makes a path relative. This is very useful for templates. For example, you normally include a
  # stylesheet in a template. If you specify the filename of the stylesheet directly, the reference
  # to the stylesheet in the output file of a page file that is not in the same directory as the
  # template would be invalid.
  #
  # By using the +relocatable+ tag you ensure that the path stays valid.
  class Relocatable

    include Webgen::Tag::Base

    # Return the relativized path for the path provided in the tag definition.
    def call(tag, body, context)
      path = param('tag.relocatable.path')
      result = ''
      begin
        result = (Webgen::Node.url(path, false).absolute? ? path : resolve_path(path, context))
      rescue URI::InvalidURIError => e
        raise Webgen::RenderError.new("Error while parsing path '#{path}': #{e.message}",
                                      self.class.name, context.dest_node, context.ref_node)
      end
      result
    end

    #######
    private
    #######

    # Resolve the path +path+ using the reference node and return the correct relative path from the
    # destination node.
    def resolve_path(path, context)
      dest_node = context.ref_node.resolve(path, context.dest_node.lang)
      if dest_node
        context.dest_node.node_info[:used_meta_info_nodes] << dest_node.alcn
        context.dest_node.route_to(dest_node)
      else
        log(:error) { "Could not resolve path '#{path}' in <#{context.ref_node.alcn}>" }
        context.dest_node.flag(:dirty)
        ''
      end
    end

  end

end
