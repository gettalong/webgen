module Webgen::SourceHandler

  class Copy

    include Base

    #TODO: path needs to be dupped before passed
    def call(parent, path)
      if false && path.ext.index('.')
        processor, *rest = path.ext.split('.')
        cp_list = @plugin_manager['Support/Misc'].content_processors
        if cp_list.keys.include?( processor )
          file_info.ext = rest.join( '.' )
        else
          processor = nil
        end
      end

      create_node(parent, path, self)
    end

    def write_info(node)
      if node.node_info[:preprocessor]
        context = Context.new( @plugin_manager['Support/Misc'].content_processors, [node] )
        context.content = File.read( node.node_info[:src] )
        context.processors[node.node_info[:preprocessor]].process( context )
        @plugin_manager['Core/CacheManager'].set( [:nodes, node.absolute_lcn, :render_info], context.cache_info )

        {:data => context.content}
      else
        {:src => node.node_info[:src] }
      end
    end

  end

end

__END__

    def create_node( parent, file_info )
      if file_info.ext.index('.')
        processor, *rest = file_info.ext.split( '.' )
        cp_list = @plugin_manager['Support/Misc'].content_processors
        if cp_list.keys.include?( processor )
          file_info.ext = rest.join( '.' )
        else
          processor = nil
        end
      end
      name = output_name( parent, file_info )

      unless node = node_exist?( parent, name, file_info.lcn )
        node = Node.new( parent, name, file_info.cn, file_info.meta_info )
        node.node_info[:src] = file_info.filename
        node.node_info[:processor] = self
        node.node_info[:preprocessor] = processor
        node.node_info[:change_proc] = proc do
          cache_info = @plugin_manager['Core/CacheManager'].get( [:nodes, node.absolute_lcn, :render_info] )
          cache_info.any? {|k,v| @plugin_manager[k].cache_info_changed?( v, node )} if cache_info
        end
      end
      node
    end

    def write_info( node )
      if node.node_info[:preprocessor]
        context = Context.new( @plugin_manager['Support/Misc'].content_processors, [node] )
        context.content = File.read( node.node_info[:src] )
        context.processors[node.node_info[:preprocessor]].process( context )
        @plugin_manager['Core/CacheManager'].set( [:nodes, node.absolute_lcn, :render_info], context.cache_info )

        {:data => context.content}
      else
        {:src => node.node_info[:src] }
      end
    end

  end

end
