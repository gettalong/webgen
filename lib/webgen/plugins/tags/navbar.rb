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

require 'util/ups'
require 'webgen/plugins/tags/tags'

module Tags

  class NavbarTag < UPS::Plugin

    NAME = 'Navigation Bar Tag'
    SHORT_DESC = 'Shows the hierarchy of current page'

    def init
      @separator = UPS::Registry['Configuration'].get_config_value( NAME, 'separator', ' / ' )
      @startTag = UPS::Registry['Configuration'].get_config_value( NAME, 'startTag', '' )
      @endTag = UPS::Registry['Configuration'].get_config_value( NAME, 'endTag', '' )
      UPS::Registry['Tags'].tags['navbar'] = self
    end


    def process_tag( tag, content, srcNode, refNode )
      out = []
      node = srcNode

      until node.nil?
        out.push( node['processor'].get_html_link( node, srcNode ) )
        node = node.parent
        node = node.parent while !node.nil? && node['virtual']
      end

      out = @startTag + out.reverse.join(@separator) + @endTag
      self.logger.debug out
      out
    end

  end

  UPS::Registry.register_plugin NavbarTag

end
