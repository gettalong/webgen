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

    used_meta_info 'orderInfo'

    tag 'sitemap'

    def process_tag( tag, srcNode, refNode )
      root = Node.root( srcNode )
      output_node( root, srcNode )
    end

    #######
    private
    #######

    def output_node( node, srcNode )
      return '' if not node.find {|c| c['int:directory?'] || c['int:pagename'] }

      processed_pagenodes = []
      out = "<#{get_param( 'levelTag' )}>"
      temp = ''
      node.sort( &Node::SORT_PROC ).each do |child|
        next unless (child['int:directory?'] || child['int:pagename']) && !processed_pagenodes.include?( child['int:pagename'] )
        processed_pagenodes << child['int:pagename'] if child['int:pagename']

        next if !node['indexFile'].nil? && node['indexFile']['int:pagename'] == child['int:pagename']

        isDir = child['int:directory?']
        subout = output_node( child, srcNode )
        link = child['processor'].get_html_link( child, srcNode ) if subout != '' || !isDir

        temp += "<#{get_param( 'itemTag' )}>#{link}" if !isDir || subout != ''
        temp += subout if isDir
        temp += "</#{get_param( 'itemTag' )}>" if !isDir || subout != ''
      end

      out += temp
      out += "</#{get_param( 'levelTag' )}>"

      (temp == '' ? temp : out)
    end

  end

end
