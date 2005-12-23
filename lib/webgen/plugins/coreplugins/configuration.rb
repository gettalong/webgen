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

# Helper class for calculating plugin dependencies.
class Dependency < Hash
  include TSort

  alias tsort_each_node each_key
  def tsort_each_child(node, &block)
    fetch(node).each(&block)
  end
end

module Webgen

  VERSION = [0, 3, 8]
  SUMMARY = "Webgen is a templated based static website generator."
  DESCRIPTION = "Webgen is a web page generator implemented in Ruby. " \
  "It is used to generate static web pages from templates and page " \
  "description files."

end

module CorePlugins

  # Responsible for loading the other plugin files and holds the basic configuration options.
  class Configuration < Webgen::Plugin

    summary "Responsible for loading plugins and holding general parameters"

    add_param 'srcDirectory', 'src', 'The directory from which the source files are read.'
    add_param 'outDirectory', 'output', 'The directory to which the output files are written.'
    add_param 'lang', 'en', 'The default language.'

    # Returns the +CommandParser+ object used for parsing the command line. You can add site
    # specific commands to it by calling the Configuration#add_cmdparser_command method!
    attr_accessor :cmdparser

    # Returns the data directory of webgen.
    def self.data_dir
      unless defined?( @@data_dir )
        @@data_dir = File.join( Config::CONFIG["datadir"], "webgen" )

        if defined?( Gem::Cache )
          gem = Gem::Cache.from_installed_gems.search( "webgen", "=#{Webgen::VERSION.join('.')}" ).last
          @@data_dir = File.join( gem.full_gem_path, "data", "webgen" ) if gem
        end

        @@data_dir =  File.dirname( $0 ) + '/../data/webgen' if !File.exists?( @@data_dir )

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

    # Instantiate the plugins in the correct order, except the classes which have a constant
    # +VIRTUAL+, and add CommandPlugin instance to the global CommandParser.
    def init_plugins
      dep = Dependency.new
      Webgen::Plugin.config.each {|k,data| dep[data.plugin] = data.dependencies || []}
      dep.tsort.each do |plugin|
        data = Webgen::Plugin.config.find {|k,v| v.plugin == plugin }[1]
        unless data.klass.const_defined?( 'VIRTUAL' ) || data.obj
          self.logger.debug { "Creating plugin of class #{data.klass.name}" }
          data.obj ||= data.klass.new
        end
      end
      Webgen::Plugin.config.keys.find_all {|klass| klass.ancestors.include?( Webgen::CommandPlugin )}.each do |cmdKlass|
        add_cmdparser_command( Webgen::Plugin.config[cmdKlass].obj )
      end
    end

  end

  # Initialize single configuration instance
  Webgen::Plugin.config[Configuration].obj = Configuration.new

end


