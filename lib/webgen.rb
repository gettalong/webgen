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

  class CreateCommand < CmdParse::Command

    def initialize
      super( 'create', false )
      self.short_desc = "Creates the basic directories and files for webgen"
      self.description = "You can optionally specify a template and/or a style which should be used. " \
      "This allows you to create a good starting template for your website."
      self.options = CmdParse::OptionParserWrapper.new do |opts|
        opts.separator "Options:"
        opts.on( '-t', '--template TEMPLATE', 'Specify the template which should be used' ) {|@template|}
        opts.on( '-s', '--style STYLE', 'Specify the style which should be used' ) {|@style|}
      end
      @template = 'default'
      @style = 'default'
    end

    def usage
      "Usage: #{commandparser.program_name} [global options] create DIR"
    end

    def execute( args )
      if args.length == 0
        raise OptionParser::MissingArgument.new( 'DIR' )
      else
        Webgen.create_website( args[0], @template, @style )
      end
    end

  end

  class CleanCommand < CmdParse::Command

    module ::FileUtils

      def fu_output_message( msg )
        logger.info { msg }
      end

      def ask_before_delete( ask, func, list, options = {} )
        newlist = [*list].collect {|e| "'" + e + "'"}.join(', ')
        if ask
          print "Really delete #{newlist}? "
          return unless /y|Y/ =~ gets.strip
        end
        self.send( func, list, options.merge( :verbose => true ) )
      end

    end

    class CleanWalker < Webgen::Plugin

      summary "Deletes the output file for each node."
      depends_on 'TreeWalker'

      attr_writer :ask

      def handle_node( node, level )
        file = node.recursive_value( 'dest' )
        return if !File.exists?( file ) || node['int:virtualNode']
        if File.directory?( file )
          begin
            FileUtils.ask_before_delete( @ask, :rmdir, file )
          rescue Errno::ENOTEMPTY => e
            logger.info "Cannot delete directory #{file}, as it is not empty!"
          end
        else
          FileUtils.ask_before_delete( @ask, :rm, file, :force => true )
        end
      end

    end

    def initialize;
      super( 'clean', false )
      self.short_desc = "Removes the generated or all files from the output directory"
      self.options = CmdParse::OptionParserWrapper.new do |opts|
        opts.separator( "Options" )
        opts.on( '--all', '-a', "Removes ALL files from the output directory" ) { @all = true }
        opts.on( '--interactive', '-i', "Ask for each file" ) { @ask = true }
      end
      @all = false
      @ask = false
    end

    def execute( args )
      if @all
        logger.info( "Deleting all files from output directory..." )
        outDir = Plugin['Configuration']['outDirectory']
        FileUtils.ask_before_delete( @ask, :rm_rf, outDir ) if File.exists?( outDir )
      else
        tree = Plugin['FileHandler'].build_tree
        logger.info( "Deleting generated files from output directory..." )
        Plugin['CleanWalker'].ask = @ask
        Plugin['TreeWalker'].execute( tree, Plugin['CleanWalker'], :backward )
      end
      logger.info( "Webgen finished 'clean' command" )
    end

  end

  class WebgenCommandParser < CmdParse::CommandParser

    def initialize
      super( true )
      self.program_name = "webgen"
      self.program_version = Webgen::VERSION
      self.options = CmdParse::OptionParserWrapper.new do |opts|
        opts.separator "Global options:"
        opts.on( "--verbosity LEVEL", "-V", Integer, "The verbosity level" ) { |verbosity| Plugin.set_param( 'Logging', 'verbosityLevel', verbosity ) }
        opts.on( "--[no-]logfile", "-L", "Log to file" ) { |logfile| Plugin.set_param( 'Logging', 'logToFile', logfile ) }
      end

      # Run command
      run = CmdParse::Command.new( 'run', false )
      run.short_desc = "Runs webgen"
      run.set_execution_block {|args| Webgen.run_webgen }
      self.add_command( run, true )

      # Show command
      show = CmdParse::Command.new( 'show', true )
      show.short_desc = "Show various information"
      self.add_command( show )

      # Show plugins command
      showPlugins = CmdParse::Command.new( 'plugins', false )
      showPlugins.short_desc = "Show the available plugins"
      showPlugins.set_execution_block do |args|
        print "List of loaded plugins:\n"

        headers = Hash.new {|h,k| h[k] = (k.nil? ? "Other Plugins" : k.gsub(/([A-Z][a-z])/, ' \1').strip) }

        ljustlength = 30 + Color.green.length + Color.reset.length
        header = ''
        Plugin.config.sort { |a, b| a[0].name <=> b[0].name }.each do |klass, data|
          newHeader = headers[klass.name[/^.*?(?=::)/]]
          unless newHeader == header
            print "\n  #{Color.bold}#{newHeader}#{Color.reset}:\n";
            header = newHeader
          end
          print "    - #{Color.green}#{data.plugin}#{Color.reset}:".ljust(ljustlength) +"#{data.summary}\n"
        end
      end
      show.add_command( showPlugins )

      # Show params command
      showConfig = CmdParse::Command.new( 'config', false )
      showConfig.short_desc = "Show the parameters of all plugins or of the specified one"
      showConfig.set_execution_block do |args|
        puts "List of plugin parameters:"
        puts
        ljustlength = 25 + Color.green.length + Color.reset.length
        Plugin.config.sort { |a, b| a[0].name[/\w*$/] <=> b[0].name[/\w*$/] }.each do |klass, data|
          next if args.length > 0 && args[0] != data.plugin
          puts "  #{Color.bold}#{data.plugin}#{Color.reset}:"
          puts "    #{Color.green}Summary:#{Color.reset}".ljust(ljustlength) + data.summary if data.summary
          puts "    #{Color.green}Description:#{Color.reset}".ljust(ljustlength) + data.description if data.description
          puts "    #{Color.green}Tag name:#{Color.reset}".ljust(ljustlength) + (data.tag == :default ? "Default tag" : data.tag) if data.tag
          puts "    #{Color.green}Handled paths:#{Color.reset}".ljust(ljustlength) + data.path.inspect if data.path

          data.table.keys.find_all {|k| /^registered_/ =~ k.to_s }.each do |k|
            name = k.to_s.sub( /^registered_/, '' ).tr('_', ' ').capitalize + " name"
            puts "    #{Color.green}#{name}:#{Color.reset}".ljust(ljustlength) + data.send( k )
          end

          if data.params
            puts "\n    #{Color.green}Parameters:#{Color.reset}"
            data.params.sort.each do |key, item|
              print "      #{Color.green}Parameter:#{Color.reset}".ljust(ljustlength)
              puts Color.lred + item.name + Color.reset + " = " + Color.lblue +  item.value.inspect + Color.reset + " (" + item.default.inspect + ")"
              puts "      #{Color.green}Description:#{Color.reset}".ljust(ljustlength) + item.description
              puts
            end
          end
          puts
        end
      end
      show.add_command( showConfig )

      self.add_command( CreateCommand.new )
      self.add_command( CleanCommand.new )
      self.add_command( CmdParse::HelpCommand.new )
      self.add_command( CmdParse::VersionCommand.new )
    end

  end

  # Run webgen
  def self.run_webgen( directory = Dir.pwd )
    Dir.chdir( directory )

    logger.info "Starting Webgen..."
    tree = Plugin['FileHandler'].build_tree
    Plugin['TreeWalker'].execute( tree ) unless tree.nil?
    Plugin['FileHandler'].write_tree( tree ) unless tree.nil?
    logger.info "Webgen finished"
  end

  # Create a website in the +directory+, using the +template+ and the +style+.
  def self.create_website( directory, template = 'default', style = 'default' )
    templateFile = File.join( CorePlugins::Configuration.data_dir, 'website_templates', template )
    styleFile = File.join( CorePlugins::Configuration.data_dir, 'website_styles', style )
    raise ArgumentError.new( "Invalid template <#{template}>" ) if !File.directory?( templateFile )
    raise ArgumentError.new( "Invalid style <#{style}>" ) if !File.directory?( styleFile )

    FileUtils.cp_r( templateFile, directory )
    FileUtils.cp( Dir[File.join( styleFile, '*' )], File.join( templateFile, 'src' ) )
  end

  # Main program for the webgen CLI command.
  def self.cli_main
    Color.colorify if $stdout.isatty && !Config::CONFIG['arch'].include?( 'mswin32' )
    Plugin['Configuration'].cmdparser = WebgenCommandParser.new
    Plugin['Configuration'].cmdparser.parse do |level, cmdName|
      Plugin['Configuration'].init_all if level == 0
    end
  end

end
