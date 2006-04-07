class SampleHandler < FileHandlers::DefaultFileHandler

  handle_path_pattern '**/*.page'
  handle_extension 'page'

  def initialize( plugin_manager )
    super
    handle_extension 'page'
    handle_path_pattern '**/*.page'
  end

  def create_node( path, parent )
    if (node = parent.find {|c| c.path == File.basename( path )}).nil?
      node = Node.new( parent, File.basename( path ) )
    end
    node
  end

end
