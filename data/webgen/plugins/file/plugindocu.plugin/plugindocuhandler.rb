require 'yaml'

module FileHandlers

  class PluginDocuHandler < DefaultHandler

    def create_node( parent, file_info )
      begin
        page = WebPageFormat.create_page_from_file( file_info.filename, file_info.meta_info )
      rescue WebPageFormatError => e
        log(:error) { "Invalid plugin docu file <#{file_info.filename}>: #{e.message}" }
        return nil
      end

      plugins = [page.meta_info['plugins']].flatten.compact.collect do |pattern|
        @plugin_manager.plugin_infos[/#{pattern}/].collect do |name, plugin_data|
          (plugin_data['plugin']['nodocu'] ? nil : name)
        end
      end.flatten.compact.sort

      plugin_nodes = plugins.collect do |name|
        filename = name.downcase.tr( '/', '_' ) + '.page'
        docu_block = @plugin_manager.documentation_for( name, 'documentation', :block )
        n = @plugin_manager['Core/FileHandler'].create_node( filename, parent, @plugin_manager['File/PageHandler'] ) do |pn, fi, h|
          fi.meta_info['title'] = name
          h.create_node_from_data( pn, fi, '' )
        end
        n.node_info[:page].blocks['content'] = page.blocks['template'] || default_content_block
        n.node_info[:page].blocks['documentation'] = docu_block if docu_block
        n.node_info[:plugin_for_docu] = name

        old_proc = n.node_info[:change_proc]
        n.node_info[:change_proc] = proc do |node|
          [
           old_proc.call( node ),
           @plugin_manager['Core/FileHandler'].file_changed?( file_info.filename ),
           (!page.blocks['template'] && @plugin_manager['Core/FileHandler'].file_changed?( get_resource_src( :template ) )),
           (docu_block && @plugin_manager['Core/FileHandler'].file_changed?( @plugin_manager.documentation_for( name, 'documentation', :src ) ))
           ].any?
        end
        n
      end

      if page.meta_info['generateIndexPage']
        filename = page.meta_info['generateIndexPage'] + '.page'
        n = @plugin_manager['Core/FileHandler'].create_node( filename, parent, @plugin_manager['File/PageHandler'] ) do |pn, fi, h|
          h.create_node_from_data( pn, fi, '' )
        end
        n.node_info[:page].blocks['content'] = page.blocks['index'] || default_index_block
        n.node_info[:docu_plugins] = plugin_nodes

        old_proc = n.node_info[:change_proc]
        n.node_info[:change_proc] = proc do |node|
          [
           old_proc.call( node ),
           plugins.hash != @plugin_manager['Core/CacheManager'].get( [:nodes, node.absolute_lcn, :plugin_docu_plugins], plugins.hash ),
           @plugin_manager['Core/FileHandler'].file_changed?( file_info.filename ),
           (!page.blocks['index'] && @plugin_manager['Core/FileHandler'].file_changed?( get_resource_src( :index ) ))
          ].any?
        end
      end
      nil
    end

    def get_resource_src( type = :template )
      case type
      when :template then @plugin_manager.resources['webgen/plugindocu/template']['src']
      when :index then @plugin_manager.resources['webgen/plugindocu/index']['src']
      end
    end

    def default_content_block
      read_default_block( get_resource_src( :template ) )
    end

    def default_index_block
      read_default_block( get_resource_src( :index ) )
    end

    def read_default_block( file )
      begin
        template = WebPageFormat.create_page_from_file( file )
        block = template.blocks['content']
      rescue WebPageFormatError => e
        log(:error) { "Invalid default template for plugin docu index in <#{file}>: #{e.message}" }
      end
      block
    end

  end

end
