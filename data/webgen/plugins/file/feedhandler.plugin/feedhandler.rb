module FileHandlers

  class FeedHandler < DefaultHandler

    MANDATORY_INFOS = %W[baseURL author description pages]

    def init_plugin
      @templates = {}
    end

    def create_node( parent, file_info )
      begin
        page = WebPageFormat.create_page_from_file( file_info.filename, file_info.meta_info )
      rescue WebPageFormatError => e
        log(:error) { "Invalid feed file <#{file_info.filename}>: #{e.message}" }
        return nil
      end
      file_info.meta_info = page.meta_info
      file_info.meta_info['title'] ||= ''
      file_info.meta_info['link'] ||= parent.absolute_lcn

      if MANDATORY_INFOS.any? {|t| file_info.meta_info[t].nil?}
        log(:error) { "One of #{MANDATORY_INFOS.join('/')} information missing for feed <#{file_info.filename}>" }
        return nil
      end

      nodes = []
      nodes << create_feed_node( 'atom', parent, file_info, page) if file_info.meta_info['atom']
      nodes << create_feed_node( 'rss', parent, file_info, page) if file_info.meta_info['rss']

      nodes
    end

    def write_info( node )
      context = get_template_block( node.node_info[:feed_type], node ).
        render( Context.new( @plugin_manager['Support/Misc'].content_processors, [node] ) )

      @plugin_manager['Core/CacheManager'].set( [:nodes, node.absolute_lcn, :render_info], context.cache_info )

      {:data => context.content}
    end

    #######
    private
    #######

    def create_feed_node( type, parent, file_info, page )
      file_info.ext = type
      path = output_name( parent, file_info )
      unless node = node_exist?( parent, path, file_info.lcn )
        node = Node.new( parent, path, file_info.cn, file_info.meta_info )
        node.node_info[:src] = file_info.filename
        node.node_info[:processor] = self
        node.node_info[:feed] = page
        node.node_info[:feed_type] = type
        node.node_info[:change_proc] = proc do
          cache_info = @plugin_manager['Core/CacheManager'].get( [:nodes, node.absolute_lcn, :render_info] )
          cache_info.any? {|k,v| @plugin_manager[k].cache_info_changed?( v, node )} if cache_info
        end
      end
      node
    end

    def get_template_block( type, node )
      block_name = type + '_template'
      if node.node_info[:feed].blocks.has_key?( block_name )
        node.node_info[:feed].blocks[block_name]
      else
        unless @templates.has_key?( type )
          file = @plugin_manager.resources['webgen/feedhandler/template/' + type]['src']
          begin
            template = WebPageFormat.create_page_from_file( file )
            @templates[type] = template.blocks['content']
          rescue WebPageFormatError => e
            log(:error) { "Invalid feed file <#{file_info.filename}>: #{e.message}" }
          end
        end
        @templates[type]
      end
    end

  end

end
