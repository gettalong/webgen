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
  class LangTag < DefaultTag

    NAME = 'Language Tag'
    SHORT_DESC = 'Provides links to translations of the page'


    def init
      register_config_value( 'separator', ' | ' )
      register_config_value( 'showSingleLang', true )
      UPS::Registry['Tags'].tags['lang'] = self
    end


    def process_tag( tag, node, refNode )
      output = node.parent.children.sort do |a, b| a['lang'] <=> b['lang'] end.collect do |node|
        node['processor'].get_html_link( node, node, node['lang'] )
      end.join( get_config_value( 'separator' ) )
      return ( get_config_value( 'showSingleLang' ) || node.parent.children.length > 1 ? output : "" )
    end

  end

  UPS::Registry.register_plugin LangTag

end
