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

    infos( :author => Webgen::AUTHOR,
           :summary => 'Provides links to translations of the page'
           )

    param 'separator', ' | ', 'Separates the languages from each other.'
    param 'showSingleLang', true, 'Should the link be shown although the page is only available in one language?'
    param 'showOwnLang', true, 'Should the link to the currently displayed language page be shown? '

    register_tag 'langbar'

    def process_tag( tag, chain )
      cur_node = chain.last
      langs = cur_node.parent.find_all {|child| child.node_info[:pagename] == cur_node.node_info[:pagename] }
      nr_langs = langs.length
      langs = langs.
        delete_if {|child| (cur_node['lang'] == child['lang'] && !param( 'showOwnLang' )) }.
        sort {|a, b| a['lang'] <=> b['lang']}.
        collect {|n| n.link_from( cur_node, :resolve_lang_node => false, :link_text => n['lang'] )}.
        join( param( 'separator' ) )
      ( param( 'showSingleLang' ) || nr_langs > 1 ? langs : "" )
    end

  end

end
