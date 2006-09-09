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

  # Generates a list with all the languages for a page.
  class LangbarTag < DefaultTag

    infos :summary => 'Provides links to translations of the page'

    param 'separator', ' | ', 'Separates the languages from each other.'
    param 'showSingleLang', true, 'Should the link be shown although the page is only available in one language?'
    param 'showOwnLang', true, 'Should the link to the currently displayed language page be shown? '

    register_tag 'langbar'

    def process_tag( tag, chain )
      langs = chain.last.parent.find_all {|child| child.node_info[:pagename] == chain.last.node_info[:pagename] }
      nr_langs = langs.length
      langs = langs.
        delete_if {|child| (chain.last['lang'] == child['lang'] && !param( 'showOwnLang' )) }.
        sort {|a, b| a['lang'] <=> b['lang']}.
        collect {|n| n.link_from( n, :link_text => n['lang'] )}.
        join( param( 'separator' ) )
      ( param( 'showSingleLang' ) || nr_langs > 1 ? langs : "" )
    end

  end

end
