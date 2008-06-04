require 'webgen/tag'

module Webgen::Tag

  # Provides easy access to the meta information of a node.
  class Metainfo

    include Base

    def call(tag, body, context)
      output = ''
      if tag == 'lang'
        output = context.dest_node.lang
      elsif context.dest_node[tag]
        output = context.dest_node[tag].to_s
      else
        log(:warn) { "No value for tag '#{tag}' in <#{context.ref_node.absolute_lcn}> found in <#{context.dest_node.absolute_lcn}>" }
      end
      output
    end

  end

end
