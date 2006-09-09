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

load_plugin 'webgen/plugins/tags/tag_processor'
load_plugin 'webgen/plugins/filehandlers/page'

module Tags

  # Generates a sitemap. The sitemap contains the hierarchy of all pages on the web site.
  class SitemapTag < DefaultTag

    infos :summary => 'Shows all page files of the website'
    param 'levelTag', 'ul', 'The tag used for creating a new hierarchy level.'
    param 'itemTag', 'li', 'The tag used for hierarchy items.'
    param 'honorInMenu', true, 'Only pages for which the \'inMenu\' meta information is set are shown in ' +
      'the sitemap if true'

    register_tag 'sitemap'

=begin
TODO: move to doc
- used meta info 'orderInfo' (orderInfo has to be an integer, not a float)
- respects language (only shows pages in the current language)
=end

    def process_tag( tag, chain )
      root = Node.root( chain.last )
      output_node( root, chain.last )
    end

    #######
    private
    #######

    def output_node( node, src_node )
      nodes = node.select do |child|
        child.is_directory? || (child.kind_of?( FileHandlers::PageHandler::PageNode ) && child['lang'] == src_node['lang'])
      end
      return '' if nodes.empty?

      out = "<#{param( 'levelTag' )}>"
      temp = ''
      nodes.sort.each do |child|
        next if !child.is_directory? &&
          ((param( 'honorInMenu' ) && !child['inMenu']) ||
           (!node['indexFile'].nil? && node['indexFile'].node_info[:pagename] == child.node_info[:pagename] && !node.parent.nil?))

        subout = output_node( child, src_node )
        link = child.link_from( src_node ) if !child.is_directory? || subout != ''

        temp += "<#{param( 'itemTag' )}>#{link}" if !child.is_directory? || subout != ''
        temp += subout if child.is_directory?
        temp += "</#{param( 'itemTag' )}>" if !child.is_directory? || subout != ''
      end

      out += temp
      out += "</#{param( 'levelTag' )}>"

      (temp == '' ? temp : out)
    end

  end

end
