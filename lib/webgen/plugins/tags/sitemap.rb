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

require 'webgen/plugins/tags/tags'

module Tags

  # Generates a sitemap. The sitemap contains the hierarchy of all pages on the web site.
  class SitemapTag < DefaultTag

    summary 'Shows all pages of the website'
    add_param 'levelTag', 'ul', 'The tag used for creating a new hierarchy level.'
    add_param 'itemTag', 'li', 'The tag used for pages.'
    depends_on 'Tags'

    def initialize
      super
      register_tag( 'sitemap' )
    end

    def process_tag( tag, srcNode, refNode )
      root = Node.root( srcNode )
      output_node( root, srcNode )
    end

    #######
    private
    #######

    def output_node( node, srcNode )
      return '' if not node.find {|c| c.kind_of?( FileHandlers::DirHandler::DirNode ) || c.kind_of?( FileHandlers::PageHandler::PageNode ) }

      out = "<#{get_param( 'levelTag' )}>"
      node.each do |child|
        next unless child.kind_of?( FileHandlers::DirHandler::DirNode ) || child.kind_of?( FileHandlers::PageHandler::PageNode )

        isDir = child.kind_of?( FileHandlers::DirHandler::DirNode )
        subout = output_node( child, srcNode )
        if subout != '' || !isDir
          langNode = child['processor'].get_lang_node( child, srcNode['lang'] )
          link = langNode['processor'].get_html_link( langNode, srcNode, ( isDir ? langNode['directoryName'] || child['directoryName'] : langNode['title'] ) )
        end

        out += "<#{get_param( 'itemTag' )}>#{link}" if !isDir || subout != ''
        out += subout if isDir
        out += "</#{get_param( 'itemTag' )}>" if !isDir || subout != ''
      end

      out += "</#{get_param( 'levelTag' )}>"
    end

  end

end
