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

  # Generates a list with all the languages for a page.
  class LangTag < UPS::Plugin

    NAME = 'Language Tag'
    SHORT_DESC = 'Provides a link to translations of the page'

    def init
      @separator = UPS::Registry['Configuration'].get_config_value( NAME, 'separator', ' | ' )
      UPS::Registry['Tags'].tags['lang'] = self
    end


    def process_tag( tag, content, node, refNode )
      node.parent.children.sort { |a, b| a['lang'] <=> b['lang'] }.collect do |node|
        node['processor'].get_html_link( node, node, node['lang'] )
      end.join(@separator)
    end

  end

  UPS::Registry.register_plugin LangTag

end
