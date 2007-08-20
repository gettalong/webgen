module Tag

  # This plugin registers itself as default plugin for tags. It substitutes tags with their
  # respective values from the node meta data.
  #
  # This is very useful if you want to add new meta information to the page files and simple copy
  # the values to the output file.
  class Meta < DefaultTag

    def process_tag( tag, body, ref_node, node )
      output = ''
      if node[tag]
        output = node[tag].to_s
      else
        log(:warn) { "No value for tag '#{tag}' in <#{ref_node.node_info[:src]}> found in <#{node.node_info[:src]}>" }
      end
      output
    end

  end

end
