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

require 'webgen/plugins/tags/tags'

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

    plugin 'Relocatable Tag'
    summary 'Adds a relative path to the specified name if necessary'

    TAG_NAME = 'relocatable'

    def check_mandatory_param( config )
      config.kind_of? String
    end


    def process_tag( tag, node, refNode )
      destNode = refNode.get_node_for_string( get_config_param( :mandatory ) )
      if !destNode.nil? && destNode.kind_of?( FileHandlers::PagePlugin::PageNode )
        destNode = destNode['processor'].get_lang_node( destNode, node['lang'] )
      end
      return ( destNode.nil? ? '' :  node.get_relpath_to_node( destNode ) + destNode['dest'] )
    end

  end

end
