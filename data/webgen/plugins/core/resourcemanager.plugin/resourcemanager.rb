require 'fileutils'

module Core

  # Handles resources in webgen that are used in page or template files or in any file that gets
  # processed.
  #
  # All plugin resources that have a valid +path+ key can be used. Additionally, memory resources
  # can be defined.
  #
  # Memory resources are resources that are only valid during a webgen run. There
  # are two predefined memory resources: <tt>webgen/memory/css</tt> and <tt>webgen/memory/js</tt>
  # which can be used by plugins to provide additional CSS styles or javascript fragments. Memory
  # resources have an additional key called +data+ which holds the data for the resource. Therefore
  # it is easy to add data to a memory resource: just append it to the contents of the +data+ key!
  class ResourceManager

    # Returns all defined memory resources.
    attr_reader :memory_resources

    def init_plugin
      @plugin_manager['Core/FileHandler'].add_msg_listener( :after_node_created, method( :add_resource_nodes ) )
      @memory_resources = {}
      define_memory_resource( 'webgen/memory/css', '/css/webgen.css',
                              "Plugins can use this resource for adding their CSS styles." )
      define_memory_resource( 'webgen/memory/js', '/js/webgen.js',
                              "Plugins can use this resource for adding their Javascript fragments." )
    end

    # This method is called after a node has been created. It uses the Core/CacheManager to check if
    # the node references a resource and if it does, it creates a node at the correct output path
    # for the resource. It uses the following cache key (which is used by File/PageHandler to store
    # processing information - is needs to have the key <tt>Tag/Resource</tt> which needs to hold an
    # array of resource names that are referenced by this node):
    #
    #     [:nodes, node.absolute_lcn, :render_info]
    #
    def add_resource_nodes( node )
      cache_info = @plugin_manager['Core/CacheManager'].get( [:nodes, node.absolute_lcn, :render_info] )
      (cache_info ? cache_info['Tag/Resource'] || [] : []).each do |res|
        res = get_resource( res )
        next if node.resolve_node( res['path'] )
        path = res['path'][0] == ?/ ? res['path'][1..-1] : res['path']
        if res['src']
          @plugin_manager['Core/FileHandler'].create_node( path, Node.root( node ), @plugin_manager['File/CopyHandler'] ) do |pn, fi, h|
            fi.filename = res['src']
            h.create_node( pn, fi )
          end
        else
          @plugin_manager['Core/FileHandler'].create_node( path, Node.root( node ), @plugin_manager['File/PageHandler'] ) do |pn, fi, h|
            h.create_node_from_data( pn, fi, "---\ntemplate: ~\n--- content, pipeline:\n#{res['data']}", false )
          end
        end
      end
    end

    # Returns the resource +name+ by first looking at the normal resources and then at the memory resources.
    def get_resource( name )
      res = @plugin_manager.resources[name] || @memory_resources[name]
      (res && res['path'] ? res : nil)
    end

    # Adds a new memory resource which can be referenced later by using +name+. The +path+ should be
    # an absolute path, like +/images/logo.png+. If not, it will be relative to the output
    # directory. You can also provide an optional description with the parameter +desc+.
    def define_memory_resource( name, path, desc = '' )
      @memory_resources[name] = {
        'name' => name,
        'path' => path,
        'desc' => desc,
        'data' => ''
      } unless @memory_resources.has_key?( name )
    end

  end

end

