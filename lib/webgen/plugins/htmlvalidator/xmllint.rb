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

require 'webgen/plugins/htmlvalidator/default'
require "tempfile"

# Allows one to get stdout and stderr from an executed command. Original version
# by Karl von Laudermann in ruby-talk #113035
class ExtendedCommand

  attr_reader :ret_code, :out_text, :err_text

  def initialize( command )
    tempfile = Tempfile.new( 'xmllint' )
    tempfile.close  # So that child process can write to it

    # Execute command, redirecting stderr to temp file
    @out_text = `#{command} 2> #{tempfile.path}`
    @ret_code = $? >> 8

    # Read temp file
    tempfile.open
    @err_text = tempfile.readlines.join
    tempfile.close
  end
end


module HTMLValidators

  class XmllintHTMLValidator < DefaultHTMLValidator

    summary "Uses xmllint to check if a file is valid and well-formed"

    add_param "args", '--catalogs --noout --valid', 'Arguments passed to the xmllint command'
    register_validator 'xmllint'

    def validate_file( filename )
      cmd = ExtendedCommand.new( "xmllint #{get_param( 'args' )} #{filename}" )
      case cmd.ret_code
      when 0
      when 1..10
        self.logger.warn { "xmllint was run on <#{filename}>, exited with the return code #{cmd.ret_code} and the error message: \n#{cmd.err_text}" }
      else
        self.logger.error { "Error running xmllint:\n#{cmd.err_text}" }
      end
    end

  end

end
