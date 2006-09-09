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

require 'rdoc/markup/simple_markup'
require 'rdoc/markup/simple_markup/to_html'
load_plugin 'webgen/plugins/contentconverters/default'

module ContentConverters

  # Handles text in RDoc format.
  class RDocConverter < DefaultContentConverter

    plugin_name 'ContentConverter/RDoc'
    infos :summary => "Handles content in RDOC format"

    register_handler 'rdoc'

    def initialize( plugin_manager )
      super
      @processor = SM::SimpleMarkup.new
      @formatter = SM::ToHtml.new
    end

    def call( content )
      @processor.convert( content, @formatter )
    rescue Exception => e
      log(:error) { "Error converting RDOC text to HTML: {e.message}" }
      content
    end

  end

end
