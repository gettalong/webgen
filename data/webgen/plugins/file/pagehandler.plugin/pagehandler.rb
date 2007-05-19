require 'webgen/listener'
require 'webgen/languages'
require 'webgen/content'
require 'webgen/node'

module FileHandlers

  # File handler plugin for handling page files.
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
      @dummy_node = Node.new( nil, 'dummy' )
      @dummy_node.node_info[:src] = 'dummy'
    end

    def create_node( file_struct, parent, meta_info )
      begin
        page = WebPageFormat.create_page_from_file( file_struct.filename, meta_info )
      rescue WebPageFormatError => e
        log(:error) { "Invalid page file <#{file_struct.filename}>: #{e.message}" }
        return nil
      end

      page.meta_info['lang'] ||= param( 'lang', 'Core/Configuration' )
      useLangPart  = ( param( 'defaultLangInFilename' ) || param( 'lang', 'Core/Configuration' ) != page.meta_info['lang'] )

      path = create_output_name( file_struct.basename, page.meta_info['lang'], useLangPart,
                                 page.meta_info['outputNameStyle'] || param( 'outputNameStyle' ) )

      unless node = node_exist?( parent, path )
        node = Node.new( parent, path, file_struct.cn )
        node.meta_info = page.meta_info
        node.node_info[:src] = file_struct.filename
        node.node_info[:processor] = self
        node.node_info[:page] = page
        node.node_info[:change_proc] = proc do
          @plugin_manager['File/TemplateHandler'].templates_for_node( node ).any? do |n|
            @plugin_manager['Core/FileHandler'].node_changed?( n )
          end
        end
      end
      node
    end

    #TODO(adept code) Same functionality as +create_node+, but uses the given +data+ as content.
    def create_node_from_data( filename, parent, data, meta_info )
      pagename = analysed_name.name + '.' + EXTENSION
      localizedPagename = analysed_name.name + '.' + data.meta_info['lang'] + '.' + EXTENSION

      if node = parent.find {|n| n =~ localizedPagename }
        log(:warn) do
          "Two input files in the same language for one page, " + \
          "using <#{node.node_info[:src]}> instead of <#{filename}>"
        end
      else
        node = PageNode.new( parent, path, data  )
        node.node_info[:src] = analysed_name.filename
        node.node_info[:processor] = self
        node.node_info[:pagename] = pagename
        node.node_info[:local_pagename] = localizedPagename
      end

      node
    end

    # Renders the block called +block_name+ of the given +node+. If +use_templates+ is +true+, then
    # the node is rendered in context of its templates.
    def render_node( node, block_name = 'content', use_templates = true )
      chain = []
      chain += @plugin_manager['File/TemplateHandler'].templates_for_node( node ) if use_templates
      chain << node

      if chain.first.node_info[:page].blocks.has_key?( block_name )
        processors = {}
        @plugin_manager.plugin_infos[/^ContentProcessor\//].each do |k,v|
          processors[v['processes']] = @plugin_manager[k]
        end
        result = chain.first.node_info[:page].blocks[block_name].render( :chain => chain, :processors => processors )
        dispatch_msg( :after_node_rendered, result, node )
      else
        log(:error) { "Error rendering node <#{node.full_path}>: no block with name '#{block_name}'" }
      end
      result
    end

    # See DefaultFileHandler#write_node.
    #
    # After the node has been written it is validated by the validator specified in the param
    # +validator+.
    def write_info( node )
      # TODO put this in a handler for after node written
      #validator = param( 'validator' )
      #validators = @plugin_manager['HtmlValidator/Default'].registered_handlers
      #unless validator.nil? || validator == '' || validators[validator].nil?
      #  validators[validator].validate_file( node.full_path )
      #end
      begin
        {:data => render_node( node )}
      rescue Exception => e
        log(:error) { "Error while processing <#{node.full_path}>: #{e.message}" }
      end
    end

    #######
    private
    #######

    def create_output_name( basename, lang, useLangPart, style )
      style.collect do |part|
        case part
        when String
          part
        when :name
          basename
        when :lang
          useLangPart ? lang : ''
        when Array
          part.include?( :lang ) && !useLangPart ? '' : create_output_name( basename, lang, useLangPart, part )
        else
          ''
        end
      end.join( '' )
    end

  end

end
