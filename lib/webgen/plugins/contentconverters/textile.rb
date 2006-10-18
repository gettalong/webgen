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

load_optional_part( 'content-converter-textile',
                    :needed_gems => ['redcloth'],
                    :error_msg => "Textile not available as content format as RedCloth could not be loaded",
                    :info => "Textile can be used as content format" ) do

  require 'redcloth'
  load_plugin 'webgen/plugins/contentconverters/default'

  module ContentConverters

    # Handles content in Textile format using RedCloth.
    class TextileConverter < DefaultContentConverter

      infos(   :name => 'ContentConverter/Textile',
             :summary => "Handles content in Textile format using RedCloth"
             )

      register_handler 'textile'

      def call( content )
        RedCloth.new( content ).to_html
      rescue Exception => e
        log(:error) { "Error converting Textile text to HTML: #{e.message}" }
        content
      end

    end

  end

end
