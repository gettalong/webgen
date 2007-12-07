class Svg2PngConverter < FileHandlers::DefaultHandler

  def init_plugin
    register_extension 'svg'
  end

  def create_node( parent, file_info )
    file_info.ext = 'png'
    name = output_name( parent, file_info )

    unless node = node_exist?( parent, name, file_info.lcn )
      node = Node.new( parent, name, file_info.cn, file_info.meta_info )
      node['title'] = name
      node.node_info[:src] = file_info.filename
      node.node_info[:processor] = self
    end
    node
  end

  def write_info( node )
    `inkscape -e #{node.full_path} #{node.node_info[:src]}`
    nil
  end

end
