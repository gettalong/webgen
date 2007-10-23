module Tag

  # This plugin registers itself as default plugin for tags. It substitutes tags with their
  # respective values from the node meta data.
  #
  # This is very useful if you want to add new meta information to the page files and simple copy
  # the values to the output file.
  class Meta < DefaultTag

    def process_tag( tag, body, context )
      output = ''
      if context.node[tag]
        output = context.node[tag].to_s
      else
        log(:warn) { "No value for tag '#{tag}' in <#{context.ref_node.node_info[:src]}> found in <#{context.node.node_info[:src]}>" }
      end
      output
    end

  end

end
