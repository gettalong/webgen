require 'erb'

module FileHandlers

  class CopyHandler < DefaultHandler

    def init_plugin
      param( 'paths' ).each {|path| register_path_pattern( path ) }
      param( 'erbPaths' ).each {|path| register_path_pattern( path ) }
    end

    def create_node( parent, file_info )
      processWithErb = param( 'erbPaths' ).any? {|pattern| File.fnmatch( pattern, file_info.filename, File::FNM_DOTMATCH )}
      file_info.ext.sub!( /^r/, '' ) if processWithErb
      name = output_name( parent, file_info )

      unless node = node_exist?( parent, name, file_info.lcn )
        node = Node.new( parent, name, file_info.cn )
        node.meta_info = node.meta_info.merge( file_info.meta_info )
        node.node_info[:src] = file_info.filename
        node.node_info[:processor] = self
        node.node_info[:preprocess] = processWithErb
      end
      node
    end

    def write_info( node )
      if node.node_info[:preprocess]
        {:data => ERB.new( File.read( node.node_info[:src] ) ).result( binding )}
      else
        {:src => node.node_info[:src] }
      end
    end

  end

end
