#
#--
#
# $Id$
#
# webgen: a template based web page generator
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

module FileHandlers

  # Super class for all page description files. Provides helper methods so that writing new plugins
  # for page description files is easy.
  class PageHandler < DefaultHandler

    # Specialized node describing a page. A page node itself is virtual, it has sub nodes which
    # describe the page files in all available languages.
    class PageNode < Node

      def initialize( parent, basename )
        super( parent )
        self['page:basename'] = self['title'] = basename
        self['src'] = self['dest'] = basename
        self['virtual'] = true
        self['processor'] = Webgen::Plugin['PageHandler']
      end

    end

    summary "Class for processing page files"
    extension 'page'
    add_param 'defaultLangInFilename', false, \
    'If true, the output files for the default language will have the ' \
    'language in the file name like all other page files. If false, they won''t.'
    add_param 'defaultContentFormat', 'textile', 'The default content format used in page files'
    depends_on 'FileHandler'

    attr_reader :formats

    def initialize
      super
      @formats = Hash.new( ContentHandlers::ContentHandler.new )
    end

    def create_node( srcName, parent )
      create_node_internally( parse_data( File.read( srcName ), srcName ), analyse_file_name( File.basename( srcName ) ), parent )
    end

    def create_node_from_data( data, srcName, parent )
      create_node_internally( parse_data( data, srcName ), analyse_file_name( File.basename( srcName ) ), parent )
    end

    def write_node( node )
      # do nothing if page base node
      return unless node['virtual'].nil?
      templateNode = Webgen::Plugin['TemplateFileHandler'].get_template_for_node( node )

      outstring = templateNode['content'].dup

      Webgen::Plugin['Tags'].substitute_tags( outstring, node, templateNode )

      File.open( node.recursive_value( 'dest' ), File::CREAT|File::TRUNC|File::RDWR ) do |file|
        file.write( outstring )
      end
    end

    def page_node_exists?( basename, dirNode )
      dirNode.find {|node| node['page:basename'] == basename}
    end
    alias :get_page_node :page_node_exists?

    def lang_node_exists?( pageNode, lang )
      langNode = pageNode.find {|child| child['lang'] == lang }
      return !langNode.nil?
    end

    def get_lang_node( node, lang = node['lang'] )
      node = node.parent unless node['page:basename']
      langNode = node.find {|child| child['lang'] == lang} ||
                 node.find {|child| child['lang'] == Webgen::Plugin['Configuration']['lang']}
      if langNode.nil?
        langNode = node.children[0]
        self.logger.warn do
          "No input file in language '#{lang}' nor the default language (#{Webgen::Plugin['Configuration']['lang']}) found," +
          "using first available input file for <#{node['title']}>"
        end
      end
      langNode
    end

    #######
    private
    #######

    def create_node_internally( data, analysed, parent )
      pageNodeExisted = get_page_node( analysed.baseName, parent )
      pageNode = pageNodeExisted || PageNode.new( parent, analysed.baseName )

      lang = data['lang'] || analysed.lang

      if lang_node_exists?( pageNode, lang )
        pageNodeExisted = false
        logger.warn do
          "Two input files in the same language for one page, " + \
          "using <#{get_lang_node( pageNode, lang ).recursive_value( 'src' )}> " + \
          "instead of <#{analysed.srcName}>"
        end
      else
        node = Node.new( pageNode )
        node.metainfo = data
        node['src'] = analysed.srcName
        node['dest'] = analysed.urlName
        node['lang'] ||= analysed.lang
        node['title'] ||= analysed.title
        node['menuOrder'] ||= analysed.menuOrder
        node['processor'] = self
        pageNode.add_child( node )
      end

      return ( pageNodeExisted ? nil : pageNode )
    end

    def parse_data( data, srcName )
      options = {}
      blocks = data.split( /^---$/ )
      if blocks.length > 0
        if blocks[0] == ''
          begin
            options = YAML::load( blocks[1] )
          rescue ArgumentError => x
            self.logger.error { "Error parsing options for file <#{srcName}>: #{x.message}" }
          end
          blocks[0..1] = []
        end
        blocks.each {|b| b.gsub!( /^(\\+)(---)$/ ) {|m| "\\" * ($1.length / 2) + $2 } }
        (options['blocks'] ||= [{'name'=>'content', 'format'=>get_param( 'defaultContentFormat' )}]).each do |blockdata|
          self.logger.debug { "Block '#{blockdata['name']}' formatted using '#{blockdata['format']}'" }
          options[blockdata['name']] = @formats[blockdata['format']].format_content( blocks.shift || '' )
        end
      end
      options
    end

    def analyse_file_name( srcName )
      matchData = /^(?:(\d+)\.)?([^.]*?)(?:\.(\w\w))?\.(.*)$/.match( srcName )
      analysed = OpenStruct.new

      self.logger.info { "Using default language for file <#{srcName}>" } if matchData[3].nil?
      analysed.lang      = matchData[3] || Webgen::Plugin['Configuration']['lang']
      analysed.baseName  = matchData[2] + '.html'
      analysed.srcName   = srcName
      langPart = ( !get_param( 'defaultLangInFilename' ) && Webgen::Plugin['Configuration']['lang'] == analysed.lang ? '' : '.' + analysed.lang )
      analysed.urlName   = matchData[2] + langPart + '.html'
      analysed.menuOrder = matchData[1].to_i
      analysed.title     = matchData[2].tr('_-', ' ').capitalize

      self.logger.debug { analysed.inspect }

      analysed
    end

  end

end


module ContentHandlers

  class ContentHandler < Webgen::Plugin

    VIRTUAL = true

    summary "Base class for all page file content handlers"

    # Register the format specified by a subclass.
    def register_format( fmt )
      self.logger.info { "Registering class #{self.class.name} for formatting '#{fmt}'" }
      Webgen::Plugin['PageHandler'].formats[fmt] = self
    end

    # Format the given +content+. Should be overridden in subclass!
    def format_content( content )
      self.logger.error { "Invalid content format specified, copying source verbatim!" }
      content
    end

  end

end
