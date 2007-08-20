module FileHandlers

  class TemplateHandler < DefaultHandler

    def create_node( parent, file_info )
      begin
        page = WebPageFormat.create_page_from_file( file_info.filename, file_info.meta_info )
      rescue WebPageFormatError => e
        log(:error) { "Invalid page file <#{file_info.filename}>: #{e.message}" }
        return nil
      end
      file_info.meta_info = page.meta_info

      path = output_name( parent, file_info )
      unless node = node_exist?( parent, path, file_info.lcn )
        node = Node.new( parent, path, file_info.cn, page.meta_info )
        node.node_info[:src] = file_info.filename
        node.node_info[:processor] = self
        node.node_info[:page] = page
        node.node_info[:no_output_file] = true
      end
      node
    end

    # Returns the template chain for +node+.
    def templates_for_node( node, lang = node['lang'] )
      if node.node_info[:templates] && node.node_info[:templates][lang]
        template_node = node.node_info[:templates][lang]
      elsif node['template'].kind_of?( String )
        template_node = node.resolve_node( node['template'], lang )
        if template_node.nil?
          log(:warn) { "Specified template '#{node['template']}' for <#{node.node_info[:src]}> not found, using default template!" }
          template_node = get_default_template( node.parent, param( 'defaultTemplate' ), lang )
        end
        (node.node_info[:templates] ||= {})[lang] = template_node
      elsif node.meta_info.has_key?( 'template' ) && node['template'].nil?
        template_node = (node.node_info[:templates] ||= {})[lang] = nil
      else
        log(:info) { "Using default template in '#{lang}' for <#{node.node_info[:src]}>" }
        template_node = (node.node_info[:templates] ||= {})[lang] = get_default_template( node.parent, param( 'defaultTemplate' ), lang )
      end

      if template_node.nil?
        []
      else
        (template_node == node ? [] : templates_for_node( template_node, lang ) + [template_node])
      end
    end

    #######
    private
    #######

    # Returns the default template of the directory node +dir+. If the template node is not found,
    # the parent directories are searched.
    def get_default_template( dir_node, default_template, lang )
      template_node = dir_node.resolve_node( default_template, lang )
      if template_node.nil?
        if dir_node.parent.nil?
          log(:warn) { "No default template '#{default_template}' in root directory found!" }
        else
          template_node = get_default_template( dir_node.parent, default_template, lang )
        end
      end
      template_node
    end

  end

end
