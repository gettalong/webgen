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

  # Generates a breadcrumb trail. It consists of all pages in the hierarchy of the
  # current page.
  #
  # For example, assuming we have the following branch
  #   /directory1/directory2/currentFile
  # this plugin will generate something like this:
  #   root / directory1 / directory2 / currentFile
  # where each listed name is linked to the corresponding file.
  class BreadcrumbTrailTag < DefaultTag

    summary 'Shows the hierarchy of current page'
    add_param 'separator', ' / ', 'Separates the hierachy entries from each other.'

    tag 'breadcrumbTrail'

    def process_tag( tag, srcNode, refNode )
      out = []
      node = srcNode

      until node.nil?
        out.push( node['processor'].get_html_link( node, srcNode ) )
        begin node = node.parent end while !node.nil? && node['virtual']
      end

      out = out.reverse.join( get_param( 'separator' ) )
      self.logger.debug { "Breadcrumb trail for <#{srcNode.recursive_value( 'src' )}>: #{out}" }
      out
    end

  end

end
