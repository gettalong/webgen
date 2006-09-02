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

require 'pathname'
require 'yaml'
require 'fileutils'
require 'webgen/config'
require 'webgen/plugin'

module Webgen


  # Base class for directories which have a README file with information stored in YAML format.
  # Should not be used directly, use its child classes!
  class DirectoryInfo

    # The unique name.
    attr_reader :name

    # Contains additional information, like a description or the creator.
    attr_reader :infos

    # Returns a new object for the given +name+.
    def initialize( name )
      @name = name
      raise ArgumentError.new( "'#{name}' is not a directory!" ) if !File.directory?( path )
      @infos = YAML::load( File.read( File.join( path, 'README' ) ) )
      raise ArgumentError.new( "'#{name}/README' does not contain key-value pairs in YAML format!" ) unless @infos.kind_of?( Hash )
    end

    # The absolute directory path. Requires that child classes have defined a constant +BASE_PATH+.
    def path
      File.expand_path( File.join( self.class::BASE_PATH, name ) )
    end

    # The files under the directory.
    def files
      Dir[File.join( path, '**', '*' )]
    end

    # Copies the files returned by +#files+ into the directory +dest+, preserving the directory
    # hierarchy.
    def copy_to( dest )
      files.each do |file|
        destpath = File.join( dest, file.sub( /^#{path}/, '' ) )
        FileUtils.mkdir_p( destpath )
        if File.directory?( file )
          FileUtils.mkdir( File.join( destpath, File.basename( file ) ) )
        else
          FileUtils.cp( file, destpath )
        end
      end
    end

    # Returns all available entries.
    def self.entries
      unless defined?( @entries )
        @entries = {}
        Dir[File.join( self::BASE_PATH, '*' )].each do |f|
          next unless File.directory?( f )
          name = File.basename( f );
          @entries[name] = self.new( name )
        end
      end
      @entries
    end

  end


  # A Web site template is a collection of files which provide a starting point for a Web site.
  # These files provide stubs for the content and should not contain any style information.
  class WebSiteTemplate < DirectoryInfo

    # Base path for the templates.
    BASE_PATH = File.join( Webgen.data_dir, 'website_templates' )

  end


  # A Web site style provides style information for a Web site. This means it contains, at least, a
  # template file and a CSS file.
  class WebSiteStyle < DirectoryInfo

    # Base path for the styles.
    BASE_PATH = File.join( Webgen.data_dir, 'website_styles' )

    # See DirectoryInfo#files
    def files
      super.select {|f| f != File.join( path, 'README' )}
    end

  end


  # A WebSite object represents a webgen website directory and is used for manipulating it.
  class WebSite

    # The website directory.
    attr_reader :directory

    # The logger used for the website
    attr_reader :logger

    # Creates a new WebSite object for the given +directory+ and loads its plugins. If the
    # +plugin_config+ parameter is given, it is used to resolve the values for plugin parameters.
    # Otherwise, a ConfigurationFile instance is used as plugin configuration.
    def initialize( directory = Dir.pwd, plugin_config = nil )
      @directory = File.expand_path( directory )
      @logger = Webgen::Logger.new

      @loader = PluginLoader.new
      @loader.load_from_dir( File.join( @directory, 'plugin' ) )
      @manager = PluginManager.new( [DEFAULT_PLUGIN_LOADER, @loader], DEFAULT_PLUGIN_LOADER.plugins + @loader.plugins )
      @manager.logger = @logger
      set_plugin_config( plugin_config )
    end

    # Returns a modified value for Configuration:srcDir and Configuration:outDir.
    def param_for_plugin( plugin_name, param )
      case [plugin_name, param]
      when ['CorePlugins::Configuration', 'srcDir'] then @srcDir
      when ['CorePlugins::Configuration', 'outDir'] then @outDir
      when ['CorePlugins::Configuration', 'websiteDir'] then @directory
      else @plugin_config.param_for_plugin( plugin_name, param )
      end
    end

    # Initializes all plugins and renders the website.
    def render
      @logger.level = @manager.param_for_plugin( 'CorePlugins::Configuration', 'loggerLevel' )
      @manager.init

      @logger.info( 'WebSite#render' ) { "Starting rendering of website #{directory}..." }
      @manager['FileHandlers::FileHandler'].render_site
      @logger.info( 'WebSite#render' ) { "Rendering of #{directory} finished" }
    end

    #######
    private
    #######

    def set_plugin_config( plugin_config )
      if plugin_config
        @manager.plugin_config = plugin_config
      else
        begin
          @manager.plugin_config = ConfigurationFile.new( File.join( @directory, 'config.yaml' ) )
        rescue ConfigurationFileInvalid => e
          @logger.error( 'WebSite#initialize' ) { e.message + ' -> Not using config file' }
        end
      end
      @srcDir = File.join( @directory, @manager.param_for_plugin(  'CorePlugins::Configuration', 'srcDir' ) ) #TODO change to allow absolute paths
      @outDir = File.join( @directory, @manager.param_for_plugin(  'CorePlugins::Configuration', 'outDir' ) )
      @plugin_config = @manager.plugin_config
      @manager.plugin_config = self
    end

    # Create a website in the +directory+, using the template +templateName+ and the style +styleName+.
    def self.create_website( directory, templateName = 'default', styleName = 'default' )
      template = WebSiteTemplate.entries[templateName]
      style = WebSiteStyle.entries[styleName]
      raise ArgumentError.new( "Invalid template '#{template}'" ) if template.nil?
      raise ArgumentError.new( "Invalid style '#{style}'" ) if style.nil?

      raise ArgumentError.new( "Directory <#{directory}> does already exist!") if File.exists?( directory )
      FileUtils.mkdir( directory )
      template.copy_to( directory )
      style.copy_to( File.join( directory, 'src' ) )
    end

  end


  # Raised when a configuration file has an invalid structure
  class ConfigurationFileInvalid < RuntimeError; end

  # Represents the configuration file of a website.
  class ConfigurationFile

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

    # See PluginManager#param_for_plugin .
    def param_for_plugin( plugin_name, param )
      if @config.has_key?( plugin_name ) && @config[plugin_name].has_key?( param )
        @config[plugin_name][param]
      else
        raise PluginParamNotFound.new( plugin_name, param )
      end
    end

    #######
    private
    #######

    def check_config
      if !@config.kind_of?( Hash ) || !@config.all? {|k,v| v.kind_of?( Hash )}
        raise ConfigurationFileInvalid.new( 'Structure of config file is not valid, has to be a Hash of Hashes' )
      end
    end

  end

end
