require 'erb'

module FileHandlers

  class CopyHandler < DefaultHandler

    def init_plugin
      param( 'paths' ).each {|path| register_path_pattern( path ) }
      param( 'erbPaths' ).each {|path| register_path_pattern( path ) }
    end

    def create_node( file_struct, parent, meta_info )
      processWithErb = param( 'erbPaths' ).any? {|pattern| File.fnmatch( pattern, file_struct.filename, File::FNM_DOTMATCH )}
      name = File.basename( file_struct.filename )
      name = name.sub( /\.r([^.]+)$/, '.\1' ) if processWithErb
      file_struct.cn = file_struct.cn.sub( /\.r([^.]+)$/, '.\1' ) if processWithErb

      unless node = @plugin_manager['Core/FileHandler'].node_exist?( parent, name )
        node = Node.new( parent, name, file_struct.cn )
        node.meta_info.update( meta_info )
        node.node_info[:src] = file_struct.filename
        node.node_info[:processor] = self
        node.node_info[:preprocess] = processWithErb
      end
      node
    end

    # Copy the file to the destination directory if it has been modified.
    def write_info( node )
      if node.node_info[:preprocess]
        {:data => ERB.new( File.read( node.node_info[:src] ) ).result( binding )}
      else
        {:src => node.node_info[:src] }
      end
    end

  end

end
