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

  class WikiLinkTag < DefaultTag

    infos :summary => 'Adds a link to a wiki page'

    param 'linkText', nil, 'The text of the link. If it is not specified, the title of the current page is used.'
    param 'rootURL', '/wiki/wiki.pl?', 'The root URL for the wiki link, ie. the path to the wiki CGI.'
    param 'relURL', nil, 'The relativ URL for the wiki link (the varying part that is appended to rootURL). ' +
      'If it is not specified, the title of the current page is used.'
    param 'invalidChars', ' &;', 'The characters which are invalid in wiki URLs.'
    param 'replacementChar', '_', 'The character(s) which should be used instead of the invalid characters.'
    set_mandatory 'rootURL'
    set_mandatory 'invalidChars'
    set_mandatory 'replacementChar'

=begin
TODO: move to do
- used_meta_info 'title'
=end

    register_tag 'wikilink'

    def process_tag( tag, chain )
      "<a href=\"#{link( chain.last )}\">#{param( 'linkText' ) || chain.last['title']}</a>"
    end

    #######
    private
    #######

    def link( node )
      rootURL = param( 'rootURL' )
      relURL = param( 'relURL' ) || node['title']
      rootURL + relURL.tr( param( 'invalidChars' ), param( 'replacementChar' ) )
    end

  end

end
