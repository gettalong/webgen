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
require 'uri'

module Tags

  # Changes the path of file. This is very useful for templates. For example, you normally include a
  # stylesheet in a template. If you specify the filename of the stylesheet directly, the reference
  # to the stylesheet in the output file of a page file that is not in the same directory as the template
  # would be invalid.
  #
  # By using the +relocatable+ tag you ensure that the path stays valid.
  #
  # Tag parameter: the name of the file which should be relocated
  class RelocatableTag < DefaultTag

    summary 'Adds a relative path to the specified name if necessary'
    depends_on 'Tags'
    add_param 'item', nil, 'The item which should be relocatable'
    set_mandatory 'item', true

    def initialize
      super
      register_tag( 'relocatable' )
    end

    def process_tag( tag, node, refNode )
      uri_string = get_param( 'item' )
      result = ''
      unless uri_string.nil?
        begin
          uri = URI.parse( uri_string )
          if uri.absolute?
            result = uri_string
          else
            destNode = refNode.node_for_string( uri.path )
            qf = (uri.query.nil? ? '' : '?'+ uri.query ) + (uri.fragment.nil? ? '' : '#' + uri.fragment)
            result = ( destNode.nil? ? '' :  node.relpath_to_node( destNode['processor'].get_node_for_lang( destNode, node['lang'] ) ) + qf )
          end
        rescue URI::InvalidURIError => e
          logger.error { "Error while parsing URI for relocatable tag: #{e.message}" }
        end
      end
      return result
    end

  end

end
