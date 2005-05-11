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

require 'webgen/plugins/filehandler/filehandler'
require 'yaml'
require 'erb'

module FileHandlers

  # Super class for all page description files. Provides helper methods so that writing new plugins
  # for page description files is easy.
  class PageHandler < DefaultFileHandler

    class PageNode < Node; end;

    summary "Class for processing page files"
    extension 'page'
    add_param 'defaultLangInFilename', false, \
    'If true, the output files for the default language will have the ' \
    'language in the file name like all other page files. If false, they won''t.'
    add_param 'defaultContentFormat', 'textile', 'The default content format used in page files.'
    add_param 'outputNameStyle', [:name, ['.', :lang], '.html'], 'Defines how the output name should be built. The correct name will be used for ' \
    'the :name part and the file language will be used for the :lang part. If <defaultLangInFilename> is true, the :lang part or the subarray in which '\
    'the :lang part was defined, will be omitted.'
    add_param 'validator', 'xmllint', 'The validator for checking HTML files on their validness. Set to "" or nil to prevent checking.'
    add_param 'useERB', true, 'Specifies if the content blocks of the page file should be processed with ERB before they are formatted.'
    depends_on 'FileHandler', 'DefaultContentHandler'

    def create_node( srcName, parent )
      create_node_internally( parse_data( File.read( srcName ), srcName ), analyse_file_name( File.basename( srcName ) ), parent )
    end

    def create_node_from_data( data, srcName, parent )
      create_node_internally( parse_data( data, srcName ), analyse_file_name( File.basename( srcName ) ), parent )
    end

    def write_node( node )
      templateNode = Webgen::Plugin['TemplateFileHandler'].get_template_for_node( node )

      useERB = node['useERB'] || ( node['useERB'].nil? && get_param( 'useERB' ) )
      node['blocks'].each do |blockdata|
        begin
          content = ( useERB ? ERB.new( blockdata['data'] ).result( binding ) : blockdata['data'] )
        rescue Exception => e
          logger.error { "ERB threw an error while processing an ERB template (<#{node.recursive_value('src')}>, block #{blockdata['name']}): #{e.message}" }
          content = blockdata['data']
        end
        node[blockdata['name']] = Webgen::Plugin['DefaultContentHandler'].get_format( blockdata['format'] ).format_content( content )
      end
      begin
        outstring = ERB.new( templateNode['content'] ).result( binding )
      rescue Exception => e
        logger.error { "ERB threw an error while processing an ERB template (<#{templateNode.recursive_value('src')}>: #{e.message}" }
        outstring = templateNode['content'].dup
      end
      outstring = Webgen::Plugin['Tags'].substitute_tags( outstring, node, templateNode )

      File.open( node.recursive_value( 'dest' ), File::CREAT|File::TRUNC|File::RDWR ) do |file|
        file.write( outstring )
      end

      validator = get_param( 'validator' )
      unless validator.nil? || validator == ''
        Webgen::Plugin['DefaultHTMLValidator'].get_validator( validator ).validate_file( node.recursive_value( 'dest' ) )
      end
    end

    # Returns a page node in +dirNode+ which has the name +name+.
    def get_page_node_by_name( dirNode, name )
      dirNode.find {|node| node['int:pagename'] == name}
    end

    # Returns the page node for the given language.
    def get_node_for_lang( node, lang )
      dirNode = node.parent
      pageNode = dirNode.find {|child| child['int:pagename'] == node['int:pagename'] && child['lang'] == lang}
      if pageNode.nil?
        self.logger.info { "No page node in language '#{lang}' for page '#{node['title']}' found, trying default language" }
        pageNode = dirNode.find {|child| child['int:pagename'] == node['int:pagename'] && child['lang'] == Webgen::Plugin['Configuration']['lang']}
        if pageNode.nil?
          self.logger.warn do
            "No page node in default language (#{Webgen::Plugin['Configuration']['lang']}) " + \
            "for page '#{node['title']}' found, using supplied page node"
          end
          pageNode = node
        end
      end
      pageNode
    end

    #######
    private
    #######

    def create_node_internally( data, analysed, parent )
      lang = data['lang'] || analysed.lang

      if node = parent.find {|node| node['page:commonName'] == analysed.name && node['lang'] == lang }
        logger.warn do
          "Two input files in the same language for one page, " + \
          "using <#{node.recursive_value( 'src' )}> instead of <#{analysed.srcName}>"
        end
      else
        node = PageNode.new( parent )
        node.metainfo = data
        node['lang'] ||= analysed.lang
        node['title'] ||= analysed.title
        node['orderInfo'] ||= analysed.orderInfo
        node['src'] = analysed.srcName
        node['dest'] = create_output_name( analysed, node['outputNameStyle'] || get_param( 'outputNameStyle' ) )
        node['int:pagename'] = create_output_name( analysed, node['outputNameStyle'] || get_param( 'outputNameStyle' ), true )
        node['processor'] = self
      end

      return node
    end

    def parse_data( data, srcName )
      options = {}
      blocks = data.split( /^---\s*$/ )
      if blocks.length > 0
        if blocks[0] == ''
          begin
            options = YAML::load( blocks[1] )
          rescue ArgumentError => x
            self.logger.error { "Error parsing options for file <#{srcName}>: #{x.message}" }
          end
          blocks[0..1] = []
        end
        blocks.each {|b| b.gsub!( /^(\\+)(---\s*)$/ ) {|m| "\\" * ($1.length / 2) + $2 } }
        (options['blocks'] ||= [{'name'=>'content', 'format'=>get_param( 'defaultContentFormat' )}]).each do |blockdata|
          if !blockdata.kind_of?( Hash ) || !blockdata['name'] || !blockdata['format']
            self.logger.error { "Block meta information in <#{srcName}> invalid (#{blockdata.inspect})" }
            next
          end
          self.logger.debug { "Block '#{blockdata['name']}' formatted using '#{blockdata['format']}'" }
          blockdata['data'] = blocks.shift || ''
        end
      end
      options
    end

    def analyse_file_name( srcName )
      matchData = /^(?:(\d+)\.)?([^.]*?)(?:\.(\w\w))?\.(.*)$/.match( srcName )
      analysed = OpenStruct.new

      self.logger.info { "Using default language for file <#{srcName}>" } if matchData[3].nil?
      analysed.lang      = matchData[3] || Webgen::Plugin['Configuration']['lang']
      analysed.srcName   = srcName
      analysed.useLangPart  = ( !get_param( 'defaultLangInFilename' ) && Webgen::Plugin['Configuration']['lang'] == analysed.lang ? false : true )
      analysed.name      = matchData[2]
      analysed.orderInfo = matchData[1].to_i
      analysed.title     = matchData[2].tr('_-', ' ').capitalize

      self.logger.debug { analysed.inspect }

      analysed
    end

    def create_output_name( analysed, data, omitLangPart = false )
      data.collect do |part|
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
