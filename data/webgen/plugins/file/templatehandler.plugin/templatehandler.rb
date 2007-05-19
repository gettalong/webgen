module FileHandlers

  class TemplateHandler < DefaultHandler

    def create_node( file_struct, parent, meta_info )
      begin
        page = Page.create_from_file( file_struct.filename, meta_info )
      rescue PageInvalid => e
        log(:error) { "Invalid page file <#{file_struct.filename}>: #{e.message}" }
        return nil
      end

      path = File.basename( file_struct.filename )
      unless node = node_exist?( parent, path )
        node = Node.new( parent, path, file_struct.cn )
        node.meta_info = page.meta_info
        node.node_info[:src] = file_struct.filename
        node.node_info[:processor] = self
        node.node_info[:page] = page
        node.node_info[:no_output] = true
      end
      node
    end

    def write_info( node )
      # do not write anything
    end

    # Returns the template chain for +node+.
    def templates_for_node( node, lang = node['lang'] )
      if node.node_info[:template]
        template_node = node.node_info[:template]
      elsif node['template'].kind_of?( String )
        template_node = node.resolve_node( node['template'], lang )
        if template_node.nil?
          log(:warn) { "Specified template '#{node['template']}' for <#{node.node_info[:src]}> not found, using default template!" }
          template_node = get_default_template( node.parent, param( 'defaultTemplate' ), lang )
        end
        node.node_info[:template] = template_node
      elsif node.meta_info.has_key?( 'template' ) && node['template'].nil?
        template_node = node.node_info[:template] = nil
      else
        log(:info) { "Using default template for <#{node.node_info[:src]}>" }
        template_node = node.node_info[:template] = get_default_template( node.parent, param( 'defaultTemplate' ), lang )
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
