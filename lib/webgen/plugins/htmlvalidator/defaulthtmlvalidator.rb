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

module HTMLValidators

  class DefaultHTMLValidator < Webgen::Plugin

    summary "Base class for all HTML validators"

    # Register the format specified by a subclass.
    def self.register_validator( validator )
      self.logger.info { "Registering class #{self.name} for validating HTML files" }
      (Webgen::Plugin.config[DefaultHTMLValidator.name].validators ||= {})[validator] = self.name
      Webgen::Plugin.config[self.name].validatorName = validator
    end

    def get_validator( name )
      if Webgen::Plugin.config[DefaultHTMLValidator.name].validators.has_key?( name )
        Webgen::Plugin.config[Webgen::Plugin.config[DefaultHTMLValidator.name].formats[name]].obj
      else
        self.logger.error { "Invalid content format specified: #{fmt}! Using DefaultHTMLValidator!" }
        Webgen::Plugin['DefaultHTMLValidator']
      end
    end

    # Should be overridden in subclass!
    def validate_file( filename )
    end

  end

end
