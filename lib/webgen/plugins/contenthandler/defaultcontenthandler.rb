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


module ContentHandlers

  class DefaultContentHandler < Webgen::Plugin

    summary "Base class for all content handlers"

    # Register the format specified by a subclass.
    def self.register_format( fmt )
      self.logger.info { "Registering class #{self.name} for formatting '#{fmt}'" }
      (Webgen::Plugin.config[DefaultContentHandler.name].formats ||= {})[fmt] = self.name
      Webgen::Plugin.config[self.name].contentFormat = fmt
    end

    def get_content_handler( fmt )
      if Webgen::Plugin.config[DefaultContentHandler.name].formats.has_key?( fmt )
        Webgen::Plugin.config[Webgen::Plugin.config[DefaultContentHandler.name].formats[fmt]].obj
      else
        self.logger.error { "Invalid content format specified: #{fmt}! Using DefaultContentHandler!" }
        Webgen::Plugin['DefaultContentHandler']
      end
    end

    # Format the given +content+. Should be overridden in subclass!
    def format_content( content )
      content
    end

  end

end
