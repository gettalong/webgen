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

  class WikiLinkTag < DefaultTag

    summary 'Adds a link to wiki page'
    depends_on 'Tags'
    add_param 'title', nil, 'The title of the link. If it is not specified, the title of the current page is used.'
    add_param 'rootURL', '/wiki/wiki.pl?', 'The root URL for the wiki link, ie. the path to the wiki CGI.'
    add_param 'relURL', nil, 'The relativ URL for the wiki link (the varying part that is appended to rootURL). ' \
    'If it is not specified, the title of the current page is used.'
    add_param 'convertSpaces', true, 'True if spaces in the relative URL should be converted to underscores.'

    def initialize
      super
      register_tag( 'wikilink' )
    end

    def process_tag( tag, node, refNode )
      "<a href=\"#{get_link( node )}\">#{get_param( 'title' ) || node['title']}</a>"
    end

    #######
    private
    #######

    def get_link( node )
      link = get_param( 'rootURL' )
      relURL = get_param( 'relURL' ) || node['title']
      link + (get_param( 'convertSpaces' ) ? relURL.tr( ' ', '_' ) : relURL )
    end

  end

end
