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

require 'find'
require 'tsort'
require 'cmdparse'
require 'webgen/node'
require 'webgen/plugin'
require 'webgen/version'

module CorePlugins

  # Responsible for loading the other plugin files and holds the basic configuration options.
  class Configuration < Webgen::Plugin

    infos :summary => "Responsible for loading plugins and holding general parameters"

    param 'srcDirectory', 'src', 'The directory from which the source files are read.'
    param 'outDirectory', 'output', 'The directory to which the output files are written.'
    param 'lang', 'en', 'The default language.'

    # Returns the +CommandParser+ object used for parsing the command line. You can add site
    # specific commands to it by calling the Configuration#add_cmdparser_command method!
    attr_accessor :cmdparser

    # Returns the data directory of webgen.
    def self.data_dir
      unless defined?( @@data_dir )
        @@data_dir = File.join( Config::CONFIG["datadir"], "webgen" )

        @@data_dir =  File.join( File.dirname( __FILE__ ), '..', '..', '..', '..', 'data', 'webgen') if !File.exists?( @@data_dir )

        if File.exists?( @@data_dir )
          logger.info { "Webgen data directory found at #{@@data_dir}" }
        else
          logger.error { "Could not locate webgen data directory!!!" }
          @@data_dir = ''
        end
      end
      @@data_dir
    end

    def add_cmdparser_command( command )
      @cmdparser.add_command( command ) if @cmdparser
    end

    # Does all the initialisation stuff
    def init_all
      load_plugins( File.dirname( __FILE__).sub( /coreplugins$/,'' ), File.dirname( __FILE__).sub(/webgen\/plugins\/coreplugins$/, '') )
      load_plugins( 'plugin', '' )
      init_plugins
    end

    # Load all plugins in the given +path+. Before +require+ is actually called the path is
    # trimmed: if +trimpath+ matches the beginning of the string, +trimpath+ is deleted from it.
    def load_plugins( path, trimpath )
      Find.find( path ) do |file|
        trimmedFile = file.gsub(/^#{trimpath}/, '')
        Find.prune unless File.directory?( file ) || ( (/.rb$/ =~ file) && !$".include?( trimmedFile ) )
        if File.file?( file )
          self.logger.debug { "Loading plugin file <#{file}>..." }
          require trimmedFile
        end
      end
    end

  end

  # Initialize single configuration instance
  #Webgen::Plugin.config[Configuration].obj = Configuration.new

end


