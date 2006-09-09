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

  # Prints out the date using a format string which will be passed to Time#strftime. Therefore you
  # can use everything Time#strftime offers.
  class DateTag < DefaultTag

    infos :summary => "Prints out the current date/time in a customizable format"
    param 'format', '%A, %B %d %H:%M:%S %Z %Y', 'The format of the date (same options as Ruby\'s Time#strftime).'

    register_tag 'date'

    def process_tag( tag, chain )
      Time.now.strftime( param( 'format' ) )
    end

  end

end
