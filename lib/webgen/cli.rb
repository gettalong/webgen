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

require 'rbconfig'
require 'fileutils'
require 'cmdparse'
require 'webgen/website'
require 'webgen/plugin'

module Webgen

  class Color

    @@colors = {:bold => [0, 1], :green => [0, 32], :lblue => [1, 34], :lred => [1, 31], :reset => [0, 0]}

    def self.colorify
      @@colors.each do |color, values|
        module_eval <<-EOF
        def Color.#{color.to_s}
        "\e[#{values[0]};#{values[1]}m"
        end
        EOF
      end
    end

    def self.method_missing( id )
      ''
    end

  end


  class CliUtils

    def self.format( content, indent = 0, width = 100 )
      content ||= ''
      return [content] if content.length + indent <= width
      lines = []
      while content.length + indent > width
        index = content[0..(width-indent-1)].rindex(' ')
        lines << (lines.empty? ? '' : ' '*indent) + content[0..index]
        content = content[index+1..-1]
      end
      lines << ' '*indent + content unless content.strip.empty?
      lines
    end

    def self.headline( text, indent = 2 )
      ' '*indent + "#{Color.bold}#{text}#{Color.reset}"
    end

    def self.section( text, ljustlength = 0, indent = 4 )
      ' '*indent + "#{Color.green}#{text}:#{Color.reset}".ljust( ljustlength - indent + Color.green.length + Color.reset.length )
    end

    def self.dirinfo_output( opts, name, dirinfo )
      ljust = 15 + opts.summary_indent.length
      opts.separator CliUtils.section( 'Name', ljust, opts.summary_indent.length + 2 ) + "#{Color.lred}#{name}#{Color.reset}"

      dirinfo.infos.sort.each do |name, value|
        desc = CliUtils.format( value, ljust )
        opts.separator CliUtils.section( name.capitalize, ljust, opts.summary_indent.length + 2 ) + desc.shift
        desc.each {|line| opts.separator line}
      end
      opts.separator ''
    end

  end


  class CreateCommand < CmdParse::Command

    def initialize
      super( 'create', false )
      self.short_desc = "Creates the basic directories and files for webgen."
      self.description = CliUtils.format( "\nIf the global verbosity level is set to 0 or 1, the created files are listed." )
      self.options = CmdParse::OptionParserWrapper.new do |opts|
        opts.separator "Options:"
        opts.on( '-t', '--template TEMPLATE', Webgen::WebSiteTemplate.entries.keys, 'Specify the template which should be used' ) {|@template|}
        opts.on( '-s', '--style STYLE', Webgen::WebSiteStyle.entries.keys, 'Specify the style which should be used' ) {|@style|}
        opts.separator ""
        opts.separator "Arguments:"
        opts.separator opts.summary_indent + "DIR: the base directory for the website"
        opts.separator ""
        opts.separator "Available templates and styles:"
        opts.separator ""
        opts.separator opts.summary_indent + "#{Color.bold}Templates#{Color.reset}"
        Webgen::WebSiteTemplate.entries.sort.each {|name, entry| CliUtils.dirinfo_output( opts, name, entry ) }
        opts.separator opts.summary_indent + "#{Color.bold}Styles#{Color.reset}"
        Webgen::WebSiteStyle.entries.sort.each {|name, entry| CliUtils.dirinfo_output( opts, name, entry ) }
      end
      @template = 'default'
      @style = 'default'
    end

    def usage
      "Usage: #{commandparser.program_name} [global options] create [options] DIR"
    end

    def execute( args )
      if args.length == 0
        raise OptionParser::MissingArgument.new( 'DIR' )
      else
        files = Webgen::WebSite.create_website( args[0], @template, @style )
        if (0..1) === commandparser.verbosity
          puts "The following files were created:"
          puts files.collect {|f| "- " + f }.join("\n")
        end
      end
    end

  end

  class UseCommand < CmdParse::Command

    def initialize( cmdparser )
      super( 'use', true )
      self.short_desc = "Changes the used website or gallery styles"

      # Use website style command.
      useWebsiteStyle = CmdParse::Command.new( 'website_style', false )
      useWebsiteStyle.short_desc = "Changes the used website style"
      useWebsiteStyle.description =
        CliUtils.format("\nCopies the style files for the website style STYLE to the website " +
                        "directory defined by the global directory option, overwritting existing " +
                        "files. If the global verbosity level is set to 0 or 1, the copied files are listed.")
      useWebsiteStyle.options = CmdParse::OptionParserWrapper.new do |opts|
        opts.separator "Available styles:"
        opts.separator ""
        Webgen::WebSiteStyle.entries.sort.each {|name, entry| CliUtils.dirinfo_output( opts, name, entry ) }
      end
      def useWebsiteStyle.usage
        "Usage: #{commandparser.program_name} [global options] use website_style STYLE"
      end
      useWebsiteStyle.set_execution_block do |args|
        if args.length == 0
          raise OptionParser::MissingArgument.new( 'STYLE' )
        else
          files = Webgen::WebSite.use_website_style( cmdparser.directory, args[0] )
          if (0..1) === cmdparser.verbosity
            puts "The following files were created or overwritten:"
            puts files.collect {|f| "- " + f }.join("\n")
          end
        end
      end
      self.add_command( useWebsiteStyle )

      # Use gallery style command.
      useGalleryStyle = CmdParse::Command.new( 'gallery_style', false )
      useGalleryStyle.short_desc = "Changes the used gallery style"
      useGalleryStyle.description =
        CliUtils.format("\nCopies the gallery templates for the gallery style STYLE to the website " +
                        "directory defined by the global directory option, overwritting existing files. " +
                        "If the global verbosity level is set to 0 or 1, the copied files are listed.")
      useGalleryStyle.options = CmdParse::OptionParserWrapper.new do |opts|
        opts.separator "Available styles:"
        opts.separator ""
        Webgen::GalleryStyle.entries.sort.each {|name, entry| CliUtils.dirinfo_output( opts, name, entry ) }
      end
      def useGalleryStyle.usage
        "Usage: #{commandparser.program_name} [global options] use gallery_style STYLE"
      end
      useGalleryStyle.set_execution_block do |args|
        if args.length == 0
          raise OptionParser::MissingArgument.new( 'STYLE' )
        else
          files = Webgen::WebSite.use_gallery_style( cmdparser.directory, args[0] )
          if (0..1) === cmdparser.verbosity
            puts "The following files were created or overwritten:"
            puts files.collect {|f| "- " + f }.join("\n")
          end
        end
      end
      self.add_command( useGalleryStyle )
    end

    #######
    private
    #######

  end


  class ShowCommand < CmdParse::Command

    def initialize( cmdparser )
      super( 'show', true )
      self.short_desc = "Shows various information"

      # Show plugins command
      showPlugins = CmdParse::Command.new( 'plugins', false )
      showPlugins.short_desc = "Shows the available plugins"
      showPlugins.set_execution_block do |args|
        puts "List of loaded plugins:"
        headers = Hash.new {|h,k| h[k] = (k.nil? ? "Other Plugins" : k.gsub(/([A-Z][a-z])/, ' \1').strip) }

        header = ''
        cmdparser.website.manager.plugin_classes.sort {|a, b| a.plugin_name <=> b.plugin_name }.each do |plugin|
          newHeader = headers[plugin.plugin_name[/^.*?(?=\/)/]]
          unless newHeader == header
            puts "\n" + CliUtils.headline( newHeader )
            header = newHeader
          end
          puts CliUtils.section( plugin.plugin_name[/\w+$/], 33 ) + CliUtils.format( plugin.config.infos[:summary], 33 ).join("\n")
        end
      end
      self.add_command( showPlugins )

      # Show config command
      showConfig = CmdParse::Command.new( 'config', false )
      showConfig.short_desc = "Shows information like the parameters for all or the matched plugins"
      showConfig.description =
        CliUtils.format( "\nIf no argument is provided, all plugins and their information are listed. If " +
                         "an argument is specified, all plugin names that match the argument are listed." ).join("\n")
      showConfig.set_execution_block do |args|
        puts "List of plugin informations:"
        puts

        cmdparser.website.manager.plugins.sort {|a, b| a[0] <=> b[0] }.each do |name, plugin|
          next if args.length > 0 && /#{args[0]}/i !~ name

          config = plugin.class.config
          puts CliUtils.headline( name )
          ljust = 25

          puts CliUtils.section( 'Summary', ljust ) + CliUtils.format( config.infos[:summary], ljust ).join("\n") if config.infos[:summary]
          puts CliUtils.section( 'Description', ljust ) + CliUtils.format( config.infos[:description], ljust ).join("\n") if config.infos[:description]
          puts CliUtils.section( 'Tag names', ljust ) + plugin.tags.join(", ") if plugin.respond_to?( :tags )
          puts CliUtils.section( 'Handles paths', ljust ) + plugin.path_patterns.collect {|r,f| f}.inspect if plugin.respond_to?( :path_patterns )
          puts CliUtils.section( 'Dependencies', ljust ) + config.dependencies.join(', ') if !config.dependencies.empty?

          if !config.params.empty?
            puts "\n" + CliUtils.section( 'Parameters' )
            config.params.sort.each do |name, item|
              print "\n" + CliUtils.section( 'Parameter', ljust, 6 )
              puts Color.lred + item.name + Color.reset + " = " +
                Color.lblue + plugin.instance_eval {param( name )}.inspect + Color.reset +
                " (" + item.default.inspect + ")"
              puts CliUtils.section( 'Description', ljust, 6 ) + CliUtils.format( item.description, ljust ).join("\n")
            end
          end

          otherinfos = config.infos.select {|k,v| ![:summary, :description, :tags, :path_patterns].include?( k ) }
          puts "\n" +CliUtils.section( 'Other Information' ) unless otherinfos.empty?
          otherinfos.each {|name, value| puts CliUtils.section( name.to_s.tr('_', ' '), ljust, 6 ) + value.inspect }

          puts
        end
      end
      self.add_command( showConfig )
    end

  end


  class CommandParser < CmdParse::CommandParser

    VERBOSITY_UNUSED = -1

    attr_reader :directory
    attr_reader :website
    attr_reader :verbosity

    def initialize
      super( true )
      @directory = Dir.pwd
      @verbosity = VERBOSITY_UNUSED

      self.program_name = "webgen"
      self.program_version = Webgen::VERSION
      self.options = CmdParse::OptionParserWrapper.new do |opts|
        opts.separator "Global options:"
        opts.on( "--directory DIR", "-d", String, "The website directory, if none specified, current directory is used." ) {|@directory|}
        opts.on( "--verbosity LEVEL", "-V", Integer, "The verbosity level (0-3)" ) {|@verbosity|}
      end

      # Run command
      run = CmdParse::Command.new( 'run', false )
      run.short_desc = "Runs webgen, ie. generates the HTML files"
      run.description = CliUtils.format("\nWith no arguments, renders the whole site. If file names are " +
                                        "specified (don't include the path/to/src/ part), only those are rendered." )
      run.set_execution_block do |args|
        @website.render( args )
      end
      self.add_command( run, true )

      self.add_command( CreateCommand.new )
      self.add_command( ShowCommand.new( self ) )
      self.add_command( UseCommand.new( self ) )
      self.add_command( CmdParse::HelpCommand.new )
      self.add_command( CmdParse::VersionCommand.new )
    end

    def param_for_plugin( plugin_name, param )
      if [plugin_name, param] == ['Core/Configuration', 'loggerLevel'] && @verbosity != VERBOSITY_UNUSED
        @verbosity
      elsif @config_file
        @config_file.param_for_plugin( plugin_name, param )
      else
        raise Webgen::PluginParamNotFound.new( plugin_name, param )
      end
    end

    def parse( argv = ARGV )
      super do |level, cmd_name|
        if level == 0
          @config_file = Webgen::WebSite.load_config_file( @directory )
          @website = Webgen::WebSite.new( @directory, self )
          @website.manager.init
          @website.manager.plugins.
            each {|name,plugin| self.add_command( plugin ) if plugin.kind_of?( Webgen::CommandPlugin ) }
        end
      end
    end

  end


  # Main program for the webgen CLI.
  def self.cli_main
    Color.colorify if $stdout.isatty && !Config::CONFIG['arch'].include?( 'mswin32' )
    cmdparser = CommandParser.new
    cmdparser.parse
  end

end
