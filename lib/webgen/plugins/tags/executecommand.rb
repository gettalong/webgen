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

require 'cgi'
require 'util/ups'
require 'webgen/plugins/tags/tags'

module Tags

  # Executes the given command and writes the standard output into the output file. All HTML special
  # characters are escaped.
  class ExecuteCommandTag < DefaultTag

    NAME = "Execute Command Tag"
    SHORT_DESC = "Executes the given command and includes its standard output"


    def initialize
      super
      self.processOutput = false
    end

    def init
      UPS::Registry['Tags'].tags['execute'] = self
    end


    def set_tag_config( config )
      if config.kind_of? String
        @command = config
      else
        Webgen::WebgenError( :TAG_PARAMETER_INVALID, config.class.name, 'String', config )
      end
    end


    def process_tag( tag, node, refNode )
      if @command.nil?
        self.logger.error { 'No command specified in tag' }
        return ''
      end

      CGI::escapeHTML( `#{@command}` )
    end

    UPS::Registry.register_plugin ExecuteCommandTag

  end

end
