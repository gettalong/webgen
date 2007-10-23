require 'webgen/listener'
require 'webgen/languages'
require 'webgen/content'
require 'webgen/node'

module FileHandlers

  # File handler plugin for handling page files.
  #
  # = Message Hooks
  #
  # The following message listening hooks (defined via symbols) are available for this plugin
  # (see Listener):
  #
  # +after_node_rendered+:: called after rendering a node via render_node
  class PageHandler < DefaultHandler

    include Listener

    def initialize
      super
      add_msg_name( :after_node_rendered )
    end

    def create_node( parent, file_info )
      page = WebPageFormat.create_page_from_file( file_info.filename, file_info.meta_info )
      internal_create_node( parent, file_info, page )
    rescue WebPageFormatError => e
      log(:error) { "Invalid page file <#{file_info.filename}>: #{e.message}" }
    end

    # Same functionality as +create_node+, but uses the given +data+ as content.
    def create_node_from_data( parent, file_info, data )
      page = WebPageFormat.create_page_from_data( data, file_info.meta_info )
      internal_create_node( parent, file_info, page )
    rescue WebPageFormatError => e
      log(:error) { "Invalid data provided for <#{file_info.filename}>: #{e.message}" }
    end

    # Renders the block called +block_name+ of the given +node+. If +use_templates+ is +true+, then
    # the node is rendered in context of its templates. Returns +nil+ if an error occurred.
    def render_node( node, block_name = 'content', use_templates = true )
      chain = []
      chain += @plugin_manager['File/TemplateHandler'].templates_for_node( node ) if use_templates
      chain << node

      if chain.first.node_info[:page].blocks.has_key?( block_name )
        context = chain.first.node_info[:page].blocks[block_name].
          render( Context.new( @plugin_manager['Support/Misc'].content_processors, chain ) )
        (context.cache_info['ContentProcessor/Blocks'] ||= [] ) << chain.first.absolute_lcn #TODO: this should be in blocks processors
        dispatch_msg( :after_node_rendered, context.content, node )
        @plugin_manager['Core/CacheManager'].set( [:nodes, node.absolute_lcn, :render_info, block_name, use_templates],
                                                  context.cache_info )
        result = context.content
      else
        log(:error) { "Error rendering node <#{node.full_path}>: no block with name '#{block_name}'" }
      end
      result
    end

    def write_info( node )
      begin
        {:data => render_node( node )}
      rescue Exception => e
        log(:error) { "Error while processing <#{node.full_path}>: #{e.message}" }
      end
    end

    #######
    private
    #######

    def internal_create_node( parent, file_info, page )
      page.meta_info['lang'] ||= param( 'lang', 'Core/Configuration' )
      file_info.meta_info = page.meta_info
      file_info.ext = 'html'
      path = output_name( parent, file_info )

      unless node = node_exist?( parent, path, file_info.lcn )
        node = Node.new( parent, path, file_info.cn, page.meta_info )
        node.node_info[:src] = file_info.filename
        node.node_info[:processor] = self
        node.node_info[:page] = page
        node.node_info[:change_proc] = proc do
          cache_info = @plugin_manager['Core/CacheManager'].get( [:nodes, node.absolute_lcn, :render_info, 'content', true] )
          cache_info.any? {|k,v| @plugin_manager[k].cache_info_changed?( v, node )} if cache_info
        end
      end
      node
    end

  end

end
