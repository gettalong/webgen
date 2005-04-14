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

  # Generates a list with all the languages for a page.
  class LanguageBarTag < DefaultTag

    summary 'Provides links to translations of the page'
    add_param 'separator', ' | ', 'Separates the languages from each other.'
    add_param 'showSingleLang', true, 'True if the language link should be shown '\
    'although the page is only available in one language.'
    depends_on 'Tags'

    def initialize
      super
      register_tag( 'langbar' )
    end

    def process_tag( tag, node, refNode )
      output = node.parent.find_all {|a| a['page:name'] == node['page:name']}.sort {|a, b| a['lang'] <=> b['lang']}.collect do |n|
        n['processor'].get_html_link( n, n, n['lang'] )
      end.join( get_param( 'separator' ) )
      return ( get_param( 'showSingleLang' ) || node.parent.children.length > 1 ? output : "" )
    end

  end

end
