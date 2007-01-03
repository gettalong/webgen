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
      files.collect do |file|
        destpath = File.join( dest, File.dirname( file ).sub( /^#{path}/, '' ) )
        FileUtils.mkdir_p( File.dirname( destpath ) )
        if File.directory?( file )
          FileUtils.mkdir_p( File.join( destpath, File.basename( file ) ) )
        else
          FileUtils.cp( file, destpath )
        end
        File.join( destpath, File.basename( file ) )
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


  # A gallery style provides style information for gallery pages. It should contains the files
  # +gallery_main.template+, +gallery_gallery.template+ and +gallery_image.template+ and an optional
  # readme file.
  class GalleryStyle < DirectoryInfo

    # Base path for the styles.
    BASE_PATH = File.join( Webgen.data_dir, 'gallery_styles' )

    # See DirectoryInfo#files
    def files
      super.select {|f| f != File.join( path, 'README' )} - plugin_files
    end

    def plugin_files
      plugin_files = []
      @infos['plugin files'].each do |pfile|
        plugin_files += Dir[File.join( path, pfile )]
      end if @infos['plugin files']
      plugin_files
    end

  end


  # A WebSite object represents a webgen website directory and is used for manipulating it.
  class WebSite

    # The website directory.
    attr_reader :directory

    # The logger used for the website
    attr_reader :logger

    # The plugin manager used for this website.
    attr_reader :manager

    # Creates a new WebSite object for the given +directory+ and loads its plugins. If the
    # +plugin_config+ parameter is given, it is used to resolve the values for plugin parameters.
    # Otherwise, a ConfigurationFile instance is used as plugin configuration.
    def initialize( directory = Dir.pwd, plugin_config = nil )
      @directory = File.expand_path( directory )
      @logger = Webgen::Logger.new

      wrapper_mod = Module.new
      wrapper_mod.module_eval { include DEFAULT_WRAPPER_MODULE }
      @loader = PluginLoader.new( wrapper_mod )
      @loader.load_from_dir( File.join( @directory, Webgen::PLUGIN_DIR ) )

      @manager = PluginManager.new( [DEFAULT_PLUGIN_LOADER, @loader], DEFAULT_PLUGIN_LOADER.plugin_classes + @loader.plugin_classes )
      @manager.logger = @logger
      set_plugin_config( plugin_config )
    end

    # Returns a modified value for Configuration:srcDir, Configuration:outDir and Configuration:websiteDir.
    def param_for_plugin( plugin_name, param )
      case [plugin_name, param]
      when ['Core/Configuration', 'srcDir'] then @srcDir
      when ['Core/Configuration', 'outDir'] then @outDir
      when ['Core/Configuration', 'websiteDir'] then @directory
      else
        (@plugin_config ? @plugin_config.param_for_plugin( plugin_name, param ) : PluginParamValueNotFound)
      end
    end

    # Initializes all plugins and renders the website.
    def render( files = [] )
      @logger.level = @manager.param_for_plugin( 'Core/Configuration', 'loggerLevel' )
      @manager.init

      @logger.info( 'WebSite#render' ) { "Starting rendering of website <#{directory}>..." }
      if files.empty?
        @manager['Core/FileHandler'].render_site
      else
        @manager['Core/FileHandler'].render_files( files )
      end
      @logger.info( 'WebSite#render' ) { "Rendering of website <#{directory}> finished" }
    end

    # Loads the configuration file from the +directory+.
    def self.load_config_file( directory = Dir.pwd )
      begin
        ConfigurationFile.new( File.join( directory, 'config.yaml' ) )
      rescue ConfigurationFileInvalid => e
        nil
      end
    end

    # Create a website in the +directory+, using the template +template_name+ and the style +style_name+.
    def self.create_website( directory, template_name = 'default', style_name = 'default' )
      template = WebSiteTemplate.entries[template_name]
      style = WebSiteStyle.entries[style_name]
      raise ArgumentError.new( "Invalid website template '#{template}'" ) if template.nil?
      raise ArgumentError.new( "Invalid website style '#{style}'" ) if style.nil?

      raise ArgumentError.new( "Directory <#{directory}> does already exist!") if File.exists?( directory )
      FileUtils.mkdir( directory )
      return template.copy_to( directory ) + style.copy_to( File.join( directory, Webgen::SRC_DIR) )
    end

    # Copies the style files for +style+ to the source directory of the website +directory+
    # overwritting exisiting files.
    def self.use_website_style( directory, style_name )
      style = WebSiteStyle.entries[style_name]
      raise ArgumentError.new( "Invalid website style '#{style_name}'" ) if style.nil?
      src_dir = File.join( directory, Webgen::SRC_DIR )
      raise ArgumentError.new( "Directory <#{src_dir}> does not exist!") unless File.exists?( src_dir )
      return style.copy_to( src_dir )
    end

    # Copies the gallery style files for +style+ to the source directory of the website +directory+
    # overwritting exisiting files.
    def self.use_gallery_style( directory, style_name )
      style = GalleryStyle.entries[style_name]
      raise ArgumentError.new( "Invalid gallery style '#{style_name}'" ) if style.nil?
      src_dir = File.join( directory, Webgen::SRC_DIR )
      plugin_dir = File.join( directory, Webgen::PLUGIN_DIR )
      raise ArgumentError.new( "Directory <#{src_dir}> does not exist!") unless File.exists?( src_dir )
      plugin_files = style.plugin_files
      FileUtils.mkdir( plugin_dir ) unless File.exists?( plugin_dir )
      FileUtils.cp( plugin_files, plugin_dir )
      return style.copy_to( src_dir ) + plugin_files.collect {|f| File.join( plugin_dir, File.basename( f ) )}
    end

    #######
    private
    #######

    def set_plugin_config( plugin_config )
      @manager.plugin_config = ( plugin_config ? plugin_config : self.class.load_config_file( @directory ) )
      @srcDir = File.join( @directory, Webgen::SRC_DIR )
      outDir = @manager.param_for_plugin(  'Core/Configuration', 'outDir' )
      @outDir = (/^(\/|[A-Za-z]:)/ =~ outDir ? outDir : File.join( @directory, outDir ) )
      @plugin_config = @manager.plugin_config
      @manager.plugin_config = self
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
        PluginParamValueNotFound
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
