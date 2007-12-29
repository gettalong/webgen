module Tag

  class Resource < DefaultTag

    def process_tag( tag, body, context )
      result = ''
      if res = @plugin_manager['Core/ResourceManager'].get_resource( param( 'name' ) )
        result, process = (param( 'insert' ) == :path ? route_to_resource( res, context ) : resource_data( res ) )
      else
        log(:error) { "Could not use resource #{param( 'name' )} in <#{context.ref_node.absolute_lcn}> as it does not exist!" }
      end
      [result, process]
    end

    def route_to_resource( res, context )
      (context.cache_info[plugin_name] ||= []) << res['name']
      ["{relocatable: #{context.ref_node.route_to( res['path'] )}}", true]
    end

    def resource_data( res )
      [(res['src'] ? File.read( res['src'] ) : res['data']), false]
    end

    def cache_info_changed?( data, node )
      false
    end

  end

end
