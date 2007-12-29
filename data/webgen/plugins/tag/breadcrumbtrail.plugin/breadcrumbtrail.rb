module Tag

  class BreadcrumbTrail < DefaultTag

    def process_tag( tag, body, context )
      out = []
      node = context.node

      omitIndexFile = if node.meta_info.has_key?( 'omitIndexFileInBreadcrumbTrail' )
                        node['omitIndexFileInBreadcrumbTrail']
                      else
                        param( 'omitIndexFile' )
                      end
      omitIndexFile = omitIndexFile && node.parent['indexFile'] &&
        node.parent['indexFile'].node_for_lang( node['lang'] ) == node

      node = node.parent if omitIndexFile

      until node.nil?
        (context.cache_info[plugin_name] ||= []) << node.absolute_lcn
        out.push( node.node_for_lang( context.node['lang'] ).link_from( context.dest_node, :context => { :caller => self.plugin_name } ) )
        node = node.parent
      end

      out[0] = '' if param( 'omitLast' ) && !omitIndexFile
      out = out.reverse.join( param( 'separator' ) )
      log(:debug) { "Breadcrumb trail for <#{context.node.absolute_lcn}>: #{out}" }
      out
    end

    def cache_info_changed?( data, node )
      @plugin_manager['Support/Misc'].nodes_meta_info_changed?( data, node )
    end

  end

end
