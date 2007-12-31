module FileHandlers

  class BlogHandler < DefaultHandler

    MANDATORY_INFOS = %W[pages]

    def create_node( parent, file_info )
      begin
        page = WebPageFormat.create_page_from_file( file_info.filename, file_info.meta_info )
      rescue WebPageFormatError => e
        log(:error) { "Invalid blog file <#{file_info.filename}>: #{e.message}" }
        return nil
      end
      file_info.meta_info = page.meta_info

      if MANDATORY_INFOS.any? {|t| file_info.meta_info[t].nil?}
        log(:error) { "One of the keys '#{MANDATORY_INFOS.join('/')}' is missing for blog <#{file_info.filename}>" }
        return nil
      end

      nodes = []
      nodes << (blog_node = create_blog_node( parent, file_info, page ))
      nodes << create_main_template( blog_node, file_info ) if !blog_node['mainPageTemplate']
      nodes << create_entry_template( blog_node, file_info ) if !blog_node['entryTemplate']
      nodes << create_main_node( blog_node, file_info ) if blog_node['createMainPage']

      nodes.compact
    end

    def pages( blog_node )
      unless blog_node.node_info[:pages]
        blog_node.node_info[:pages] = [blog_node['pages']].flatten.collect {|pat| blog_node.parent.nodes_for_pattern( pat )}.flatten.sort do |a,b|
          a.mtime <=> b.mtime
        end.reverse
      end
      blog_node.node_info[:pages]
    end

    #######
    private
    #######

    def create_blog_node( parent, file_info, page )
      path = output_name( parent, file_info )
      unless node = node_exist?( parent, path, file_info.lcn )
        node = Node.new( parent, path, file_info.cn, file_info.meta_info )
        node.node_info[:src] = file_info.filename
        node.node_info[:blog] = page
        node.node_info[:processor] = self
      end
      node
    end

    def create_main_template( blog_node, file_info )
      blog_node['mainPageTemplate'] = file_info.basename + "_main.template"
      @plugin_manager['Core/FileHandler'].create_node( blog_node['mainPageTemplate'], blog_node.parent, @plugin_manager['File/TemplateHandler'] ) do |pn, fi, h|
        fi.filename = @plugin_manager.resources['webgen/bloghandler/template/main']['src']
        h.create_node( pn, fi )
      end
    end

    def create_entry_template( blog_node, file_info )
      blog_node['entryTemplate'] = file_info.basename + "_entry.template"
      @plugin_manager['Core/FileHandler'].create_node( blog_node['entryTemplate'], blog_node.parent, @plugin_manager['File/TemplateHandler'] ) do |pn, fi, h|
        fi.filename = @plugin_manager.resources['webgen/bloghandler/template/entry']['src']
        h.create_node( pn, fi )
      end
    end

    def create_main_node( blog_node, file_info )
      file_info.ext = 'page'
      @plugin_manager['Core/FileHandler'].create_node( file_info.lcn, blog_node.parent, @plugin_manager['File/PageHandler'] ) do |pn, fi, h|
        node = h.create_node_from_data( pn, fi, "---\ntemplate: #{blog_node['mainPageTemplate']}\n---\n" )
        node.node_info[:blog] = blog_node
        node
      end
    end

  end

end
