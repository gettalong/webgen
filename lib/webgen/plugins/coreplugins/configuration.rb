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

module CorePlugins

  # Used for storing the basic configuration options.
  class Configuration < Webgen::Plugin

    plugin_name 'Core/Configuration'
    infos :summary => "Responsible for storing general parameters"

    param 'srcDir', Webgen::SRC_DIR, 'The directory from which the source files are read - is automatically set and cannot be overridden.'
    param 'outDir', 'output', 'The directory to which the output files are written.'
    param 'websiteDir', nil, 'The website directory - is automatically set and cannot be overridden!'
    param 'lang', 'en', 'The default language.'
    param 'loggerLevel', 2, 'The logging level, ranges from 0 (debug, more verbose) to 3 (error, less verbose)'

  end

end


