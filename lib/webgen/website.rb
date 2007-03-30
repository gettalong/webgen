#
#--
#
# $Id: website.rb 601 2007-02-14 21:20:44Z thomas $
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
require 'pathname'
require 'yaml'
require 'fileutils'
require 'webgen/config'
require 'webgen/plugin'

module Webgen

  class WebSite

    attr_reader :directory
    attr_reader :plugin_paths
    attr_reader :plugin_manager

    def initialize( directory = Dir.pwd  )
      @directory = File.expand_path( directory )
      @plugin_manager = PluginManager.new( [DefaultConfigurator.new( @directory )] )
      @plugin_paths = [File.join( Webgen.data_dir, 'plugins' ), File.join( directory, 'plugins' )]
    end

    def reset
      @plugin_manager = PluginManager.new
    end

    def load_plugin_infos
      Find.find( *@plugin_paths ) do |path|
        if FileTest.directory?( path ) && path =~ /\.plugin$/
          @plugin_manager.load_from_dir( path )
          Find.prune
        end
      end
    end

  end


  # Returns a modified value for Core/Configuration:srcDir, Core/Configuration:outDir and Core/Configuration:websiteDir.
  class DefaultConfigurator

    def initialize( websiteDir )
      @websiteDir = websiteDir
      @srcDir = File.join( websiteDir, 'src' ) #TODO use constant
    end

    def param( param, plugin, cur_val )
      case [plugin, param]
      when ['Core/Configuration', 'websiteDir'] then [true, @websiteDir]
      when ['Core/Configuration', 'srcDir'] then [true, @srcDir]
      when ['Core/Configuration', 'outDir'] then
        [true, (/^(\/|[A-Za-z]:)/ =~ cur_val ? cur_val : File.join( @websiteDir, cur_val ) )]
      else
        [false, cur_val]
      end
    end

  end


  # Raised when a configuration file has an invalid structure
  class ConfigurationFileInvalid < RuntimeError; end

  # Represents the configuration file of a website.
  class FileConfigurator

    # Returns the whole configuration.
    attr_reader :config

    # Reads the content of the given configuration file and initialize a new object with it.
    def initialize( config_file )
      if File.exists?( config_file )
        begin
          @config = YAML::load( File.read( config_file ) )
        rescue ArgumentError => e
          raise ConfigurationFileInvalid, e.message
        end
      else
        @config = {}
      end
      check_config
    end

    def param( param, plugin, cur_val )
      if @config.has_key?( plugin ) && @config[plugin].has_key?( param )
        [false, @config[plugin][param]]
      else
        [false, cur_val]
      end
    end

    #######
    private
    #######

    def check_config
      if !@config.kind_of?( Hash ) || !@config.all? {|k,v| v.kind_of?( Hash )}
        raise ConfigurationFileInvalid.new( 'Structure of config file is not valid, has to be a Hash of Hashes' )
      end

      if !@config.has_key?( 'Core/FileHandler' ) || !@config['Core/FileHandler'].has_key?( 'defaultMetaInfo' )
        @config.each_key do |plugin_name|
          next unless plugin_name =~ /File\//
          if @config[plugin_name]['defaultMetaInfo'].kind_of?( Hash )
            ((@config['Core/FileHandler'] ||= {})['defaultMetaInfo'] ||= {})[plugin_name] = @config[plugin_name]['defaultMetaInfo']
            @config[plugin_name].delete( 'defaultMetaInfo' )
          end
        end
      end

    end

  end

end
