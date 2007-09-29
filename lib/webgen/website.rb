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

  # Main class for rendering a website. The only required parameter is the webgen website directory
  # which should be rendered. The rendering itself is done via a simple call of the #render method.
  class WebSite

    # Returns the website directory.
    attr_reader :directory

    # Returns the list of paths which are used to load plugin bundles.
    attr_reader :plugin_paths

    # Returns the PluginManager object for this website.
    attr_reader :plugin_manager

    # Initializes a new WebSite object. The parameter +directory+ has to be a webgen website
    # directory. Also, the <tt>@plugin_paths</tt> variable is initialized (in the given order) with
    #
    # * the path to the plugin bundles shipped with webgen
    # * the user specific plugin directory (<tt>~/.webgen/plugins</tt>)
    # * the website specific plugin directory
    # * the paths in the environment variable +WEBGEN_PLUGIN_BUNDLES+.
    def initialize( directory = Dir.pwd  )
      @directory = File.expand_path( directory )
      @plugin_paths = [File.join( Webgen.data_dir, Webgen::PLUGIN_DIR ),
                       File.join( ENV['HOME'], '.webgen', Webgen::PLUGIN_DIR ),
                       File.join( @directory, Webgen::PLUGIN_DIR )] + ENV['WEBGEN_PLUGIN_BUNDLES'].to_s.split(/,/)
      reset
    end

    # Resets the website object.
    def reset
      @plugin_manager = PluginManager.new( [self] )
      @plugin_manager.load_all_plugin_bundles( @plugin_paths )
    end

    # Called by a PluginManager instance to retrieve a parameter value, should not be called
    # directly!
    def param( param, plugin, cur_val )
      case [plugin, param]
      when ['Core/Configuration', 'websiteDir'] then [true, @directory]
      when ['Core/Configuration', 'srcDir'] then [true, File.join( @directory, Webgen::SRC_DIR )]
      when ['Core/Configuration', 'outDir'] then
        [true, (/^(\/|[A-Za-z]:)/ =~ cur_val ? cur_val : File.join( @directory, cur_val ) )]
      else
        [false, cur_val]
      end
    end

    # Renders the website.
    def render
      @plugin_manager['Core/FileHandler'].render_website
    end

  end


  # Raised when a configuration file has an invalid structure
  class ConfigurationFileInvalid < RuntimeError; end

  # Represents the configuration file of a website and objects of this class can be added to the
  # list of configurators of a PluginManager instance.
  class FileConfigurator

    # Creates a FileConfigurator object for the given website directory +dir+.
    def self.for_website( dir )
      self.new( File.join( dir, 'config.yaml' ) )
    end

    # Returns the whole configuration.
    attr_reader :config

    # Reads the content of the given configuration file and initialize a new object with it.
    def initialize( config_file )
      if File.exists?( config_file )
        begin
          @config = YAML::load( File.read( config_file ) ) || {}
        rescue ArgumentError => e
          raise ConfigurationFileInvalid, e.message
        end
      else
        @config = {}
      end
      check_config
    end

    # Called by a PluginManager instance to retrieve a parameter value, should not be called
    # directly!
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
