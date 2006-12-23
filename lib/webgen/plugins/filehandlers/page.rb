#
#--
#
# $Id$
#
# webgen: template based static website generator
# Copyright (C) 2004 Thomas Leitner
#
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU
# General Public License as published by the Free Software Foundation; either version 2 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
# even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with this program; if not,
# write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#
#++
#

load_plugin 'webgen/plugins/filehandlers/filehandler'
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

    # Specialised node for URL fragments.
    class FragmentNode < Node

      def initialize( parent, path )
        super
        self.meta_info['inMenu'] = false
        self.node_info[:processor] = self
      end

      # Does not write out anything.
      def write_node
        #do nothing
      end

    end

    # Specialised noed for page files.
    class PageNode < Node

      def initialize( parent, path, pagedata )
        super( parent, path )
        @meta_info = pagedata.meta_info
        @node_info[:pagedata] = pagedata

        if pagedata.blocks['content']
          @node_info[:pagesections] = pagedata.blocks['content'].sections
          create_fragment_nodes( @node_info[:pagesections] )
        end
      end

      # Overwritten to also handle matching of the page name and the local page name.
      def =~( path )
        md = /^(#{@path}|#{@node_info[:local_pagename]}|#{@node_info[:pagename]})(?=#|$)/ =~ path
        ( md ? $& : nil )
      end

      #######
      private
      #######

      def create_fragment_nodes( sections )
        sections.each do |s|
          FragmentNode.new( self, '#' + s.id )
          create_fragment_nodes( s.subsections )
        end
      end

    end

    EXTENSION = 'page'

    infos( :name => 'File/PageHandler',
           :author => Webgen::AUTHOR,
           :summary => "Plugin for processing page files"
           )

    param 'defaultLangInFilename', false, 'If true, the output files for the default language ' +
      'will have the language in the file name like all other page files. If false, they won''t.'

    param 'outputNameStyle', [:name, ['.', :lang], '.html'], 'Defines how the output name should ' +
      'be built. The correct name will be used for the :name part and the file language will be ' +
      'used for the :lang part. If defaultLangInFilename is true, the :lang part or the ' +
      'subarray in which the :lang part was defined, will be omitted.'

    param 'validator', nil, 'The validator for checking HTML files on their validness. Set ' +
      'to an empty string or nil to prevent checking.'

    default_meta_info( 'useERB' => true, 'blocks' => [['content', 'textile']] )

    register_extension EXTENSION

    include Listener


    def initialize( plugin_manager )
      super
      add_msg_name( :after_node_rendered )
      @dummy_node = Node.new( nil, 'dummy' )
      @dummy_node.node_info[:src] = 'dummy'
    end

    def create_node( src_name, parent, meta_info )
      create_node_from_data( src_name, parent, File.read( src_name ), meta_info )
    end

    # Same functionality as +create_node+, but uses the given +data+ as content.
    def create_node_from_data( filename, parent, data, meta_info )
      begin
        data = WebPageData.new( data, @plugin_manager['ContentConverter/Default'].registered_handlers,
                                {'blocks' => meta_info['blocks']} )
      rescue WebPageDataInvalid => e
        log(:error) { "Invalid page file <#{filename}>: #{e.message}" }
        return nil
      end

      data.meta_info.update( meta_info )
      analysed_name = analyse_file_name( filename, data.meta_info['lang'] )

      data.meta_info['lang'] ||= analysed_name.lang
      data.meta_info['title'] ||= analysed_name.title
      data.meta_info['orderInfo'] ||= analysed_name.orderInfo

      pagename = analysed_name.name + '.' + EXTENSION
      localizedPagename = analysed_name.name + '.' + data.meta_info['lang'] + '.' + EXTENSION

      if node = parent.find {|n| n =~ localizedPagename }
        log(:warn) do
          "Two input files in the same language for one page, " + \
          "using <#{node.node_info[:src]}> instead of <#{filename}>"
        end
      else
        path = create_output_name( analysed_name, data.meta_info['outputNameStyle'] || param( 'outputNameStyle' ) )
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
      chain = [@dummy_node]
      content = "{block: #{block_name}}"
      chain += @plugin_manager['File/TemplateHandler'].templates_for_node( node ) if use_templates
      chain << node

      result = @plugin_manager['Core/TagProcessor'].process( content, chain )
      dispatch_msg( :after_node_rendered, result, node )
      result
    end

    # See DefaultFileHandler#write_node.
    #
    # After the node has been written it is validated by the validator specified in the param
    # +validator+.
    def write_node( node )
      outstring = render_node( node )

      File.open( node.full_path, File::CREAT|File::TRUNC|File::RDWR ) do |file|
        file.write( outstring )
      end

      validator = param( 'validator' )
      validators = @plugin_manager['HtmlValidator/Default'].registered_handlers
      unless validator.nil? || validator == '' || validators[validator].nil?
        validators[validator].validate_file( node.full_path )
      end
    end

    # See DefaultFileHandler#node_for_lang
    def node_for_lang( node, lang )
      if node['lang'] == lang
        node
      else
        node.parent.find {|c| c.node_info[:pagename] == node.node_info[:pagename] && c['lang'] == lang}
      end
    end

    # See DefaultFileHandler#link_from.
    #
    # The special +attr+ value <code>:resolve_lang_node</code> specifies if the lang node should be
    # resolved or if the current node should be used.
    def link_from( node, ref_node, attr = {} )
      lang_node = (attr[:resolve_lang_node] == false ? node : node_for_lang( node, ref_node['lang'] ) )
      if lang_node.nil?
        log(:warn) { "Translation of page node <#{node.parent.full_path + node.node_info[:pagename]}> to language '#{ref_node['lang']}' not found, can't create link"}
        node['title']
      else
        super( lang_node, ref_node, attr )
      end
    end


    #######
    private
    #######

    def analyse_file_name( filename, lang = nil )
      matchData = /^(?:(\d+)\.)?([^.]*?)(?:\.(\w\w\w?))?\.(.*)$/.match( File.basename( filename ) )
      analysed = OpenStruct.new

      log(:debug) { "Using default language for file <#{filename}>" } if lang.nil? && matchData[3].nil?
      analysed.lang      = lang || matchData[3] || param( 'lang', 'Core/Configuration' )
      analysed.filename  = filename
      analysed.useLangPart  = ( param( 'defaultLangInFilename' ) || param( 'lang', 'Core/Configuration' ) != analysed.lang )
      analysed.name      = matchData[2]
      analysed.orderInfo = matchData[1].to_i
      analysed.title     = matchData[2].tr('_-', ' ').capitalize
      log(:debug) { analysed.inspect }

      analysed
    end

    def create_output_name( analysed, style, omitLangPart = false )
      style.collect do |part|
        case part
        when String
          part
        when :name
          analysed.name
        when :lang
          analysed.useLangPart && !omitLangPart ? analysed.lang : ''
        when Array
          part.include?( :lang ) && (!analysed.useLangPart || omitLangPart) ? '' : create_output_name( analysed, part, omitLangPart )
        else
          ''
        end
      end.join( '' )
    end

  end

end
