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

require 'webgen/node'
require 'webgen/plugins/filehandler/filehandler'

module FileHandlers

  # Super class for all page description files. Provides helper methods so that writing new plugins
  # for page description files is easy.
  class PagePlugin < DefaultHandler

    # Specialized node describing a page. A page node itself is virtual, it has sub nodes which
    # describe the page files in all available languages.
    class PageNode < Node

      def initialize( parent, basename )
        super parent
        self['page:basename'] = self['title'] = basename
        self['src'] = self['dest'] = basename
        self['virtual'] = true
      end

    end


    NAME = "Page Handler"
    SHORT_DESC = "Super class for all page plugins"

    CONFIG_PARAMS = [
      {
        :name => 'defaultLangInFilename',
        :defaultValue => false,
        :description => 'If true, the output files for the default language will have the ' \
        + 'language in the file name like all other page files. If false, they won''t.'
      }
    ]


    def create_node( srcName, parent )
      data = get_file_data srcName

      fileData = analyse_file_name( File.basename( srcName ) )

      pageNode, created = get_page_node( fileData.baseName, parent )

      node = Node.new pageNode
      node.metainfo = data
      node['src'] = fileData.srcName
      node['dest'] = fileData.urlName
      node['lang'] ||= fileData.lang
      node['title'] ||= fileData.title
      node['menuOrder'] ||= fileData.menuOrder
      node['content'] ||= ''
      node['processor'] = self
      pageNode.add_child node

      return ( created ? pageNode : nil )
    end


    def write_node( node )
      # do nothing if page base node
      return unless node['virtual'].nil?
      templateNode = UPS::Registry['Template File Handler'].get_template_for_node( node )

      outstring = templateNode['content'].dup

      UPS::Registry['Tags'].substitute_tags( outstring, node, templateNode )

      File.open( node.recursive_value( 'dest' ), File::CREAT|File::TRUNC|File::RDWR ) do |file|
        file.write outstring
      end
    end


    def get_page_node( basename, dirNode )
      node = dirNode.find do |node| node['page:basename'] == basename end
      if node.nil?
        node = PageNode.new( dirNode, basename )
        created = true
      end
      [node, created]
    end


    def get_lang_node( node, lang = node['lang'] )
      node = node.parent unless node['page:basename']
      langNode = node.find do |child| child['lang'] == lang end
      langNode = node.find do |child| child['lang'] == UPS::Registry['Configuration'].lang end if langNode.nil?
      if langNode.nil?
        langNode = node.children[0]
        self.logger.warn do
          "No input file in language '#{lang}' nor the default language (#{UPS::Registry['Configuration'].lang}) found," +
          "using first available input file for <#{node['title']}>"
        end
      end
      langNode
    end

    #######
    private
    #######

    def analyse_file_name( srcName )
      matchData = /^(?:(\d+)\.)?([^.]*?)(?:\.(\w\w))?\.(.*)$/.match srcName
      fileData = Struct.new(:baseName, :srcName, :urlName, :menuOrder, :title, :lang).new

      fileData.lang      = matchData[3] || UPS::Registry['Configuration'].lang
      fileData.baseName  = matchData[2] + '.html'
      fileData.srcName   = srcName
      langPart = ( !get_config_param( 'defaultLangInFilename' ) && UPS::Registry['Configuration'].lang == fileData.lang ? '' : '.' + fileData.lang )
      fileData.urlName   = matchData[2] + langPart + '.html'
      fileData.menuOrder = matchData[1].to_i
      fileData.title     = matchData[2].tr('_-', ' ').capitalize

      self.logger.debug { fileData.to_s }

      fileData
    end

  end

  UPS::Registry.register_plugin PagePlugin

end
