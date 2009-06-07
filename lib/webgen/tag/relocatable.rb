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
      uri_string = param('tag.relocatable.path')
      result = ''
      unless uri_string.nil?
        begin
          uri = URI.parse(uri_string)
          if uri.absolute?
            result = uri_string
          else
            result = resolve_path(uri_string, context)
          end
          if result.empty?
            log(:error) { "Could not resolve path '#{uri_string}' in <#{context.ref_node.alcn}>" }
            context.dest_node.flag(:dirty)
          end
        rescue URI::InvalidURIError => e
          log(:error) { "Error while parsing path for tag relocatable in <#{context.ref_node.alcn}>: #{e.message}" }
          context.dest_node.flag(:dirty)
        end
      end
      result
    end

    #######
    private
    #######

    # Resolve the path +uri+ using the reference node and return the correct relative path from the
    # destination node.
    def resolve_path(uri, context)
      dest_node = context.ref_node.resolve(uri, context.dest_node.lang)
      (dest_node ? context.dest_node.route_to(dest_node) : '')
    end

  end

end
