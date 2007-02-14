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

    infos( :name => 'Tag/BreadcrumbTrail',
           :author => Webgen::AUTHOR,
           :summary => 'Shows the hierarchy for the current page'
           )

    param 'separator', ' / ', 'Separates the hierachy entries from each other.'
    param 'omitLast', false, 'Omits the last path component.'
    param 'omitIndexFile', false, 'Omits the last path component if it is an index file.'

    register_tag 'breadcrumbTrail'

    def process_tag( tag, chain )
      out = []
      node = chain.last

      omitIndexFile = if node.meta_info.has_key?( 'omitIndexFileInBreadcrumbTrail' )
                        node['omitIndexFileInBreadcrumbTrail']
                      else
                        param( 'omitIndexFile' )
                      end
      omitIndexFile = omitIndexFile && node.parent['indexFile'] &&
        node.parent['indexFile'].node_for_lang( node['lang'] ) == node

      node = node.parent if omitIndexFile

      until node.nil?
        out.push( node.link_from( chain.last ) )
        node = node.parent
      end

      out[0] = '' if param( 'omitLast' ) && !omitIndexFile
      out = out.reverse.join( param( 'separator' ) )
      log(:debug) { "Breadcrumb trail for <#{chain.last.node_info[:src]}>: #{out}" }
      out
    end

  end

end
