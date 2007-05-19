module FileHandlers

  # Handles virtual nodes created via the output backing section of the meta information backing
  # file.
  class VirtualFileHandler < DefaultHandler

    def create_node( struct, parent, meta_info )
      filename = File.basename( struct.filename )
      log(:error) { "No target url for virtual file in metainfo backing file specified: <#{struct.filename}>"} if meta_info['url'].nil?
      url = meta_info['url'] || filename

      # no need to check for an existing node, that is already done in FileHandler#handle_output_backing
      temp_node = Node.new( parent, filename )
      resolved_node = temp_node.resolve_node( url )
      if resolved_node
        node = Node.new( parent, temp_node.route_to( resolved_node ), filename )
      else
        node = Node.new( parent, url, filename )
      end
      parent.del_child( temp_node )

      node.meta_info.update( meta_info )
      node.node_info[:processor] = self
      node.node_info[:no_output] = true
      node
    end

  end

end
