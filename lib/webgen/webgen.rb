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

require 'optparse'
require 'rbconfig'
require 'fileutils'
require 'cmdparse'
require 'webgen/plugin'

module Webgen

  class Color

    @@colors = {:bold => [0, 1], :green => [0, 32], :lblue => [1, 34], :lred => [1, 31], :reset => [0, 0]}

    def Color.colorify
      @@colors.each do |color, values|
        module_eval <<-EOF
        def Color.#{color.to_s}
        "\e[#{values[0]};#{values[1]}m"
        end
        EOF
      end
    end

    def Color.method_missing( id )
      ''
    end

  end


  class RunWebgenCommand < CommandParser::Command

    def initialize; super( 'run' ); end

    def description; "Runs webgen. This command is used as default command when no command was issued."; end

    def usage; "Usage: #{@options.program_name} [global options] run"; end

    def execute( commandParser, args )
      logger.info "Starting Webgen..."

      # load all the files in src dir and build tree
      tree = Plugin['FileHandler'].build_tree

      # execute tree transformer plugins
      Plugin['TreeWalker'].execute( tree ) unless tree.nil?

      # generate output files
      Plugin['FileHandler'].write_tree( tree ) unless tree.nil?

      logger.info "Webgen finished"
    end
  end


  class ShowCommand < CommandParser::Command

    def initialize; super( 'show' ); end

    def description; "Shows all available plugins or their configuration items."; end

    def usage; "Usage: #{@options.program_name} [global options] show plugins|config"; end

    def execute( commandParser, args )
      case args[0]
      when 'plugins' then showPlugins
      when 'config' then showConfiguration
      else puts "You have to specify either 'plugins' or 'config'"
      end
      exit
    end

    private

    def showPlugins
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

    def showConfiguration
      print "List of configuration parameters:\n\n"
      ljustlength = 20 + Color.green.length + Color.reset.length
      Plugin.config.sort { |a, b| a[0].name <=> b[0].name }.each do |klass, data|
        next if data.params.nil?
        print "  #{Color.bold}#{data.plugin}#{Color.reset}:\n"
        data.params.sort.each do |key, item|
          print "    #{Color.green}Parameter:#{Color.reset}".ljust(ljustlength)
          puts Color.lred + item.name + Color.reset + " = " + Color.lblue +  item.value.inspect + Color.reset + " (" + item.default.inspect + ")"
          puts "    #{Color.green}Description:#{Color.reset}".ljust(ljustlength) + item.description
          print "\n"
        end
        print "\n"
      end
    end

  end


  class CreateCommand < CommandParser::Command

    def initialize; super( 'create' ); end

    def description;
      "Creates the basic directories and files for webgen. This includes the source and output directories, " \
      "the log and the plugin directory. Also, a basic template plus a CSS and an index file are created."
    end

    def usage; "Usage: #{@options.program_name} [global options] create DIR"; end

    def execute( commandParser, args )
      if args.length == 0
        raise OptionParser::MissingArgument.new( 'DIR' )
      else
        create_dir( args[0] )
        create_dir( File.join( args[0], 'src' ) )
        create_dir( File.join( args[0], 'output' ) )
        create_dir( File.join( args[0], 'log' ) )
        create_dir( File.join( args[0], 'plugin' ) )
        create_file( File.join( args[0], 'config.yaml' ), content_config_yaml )
        create_file( File.join( args[0], 'src', 'default.template' ), content_default_template )
        create_file( File.join( args[0], 'src', 'default.css' ), content_default_css )
        create_file( File.join( args[0], 'src', 'index.page' ), content_index_page )
      end
    end

    def create_dir( dir )
      Dir.mkdir( dir ) unless File.exists?( dir )
    end

    def create_file( file, content )
      File.open( file, 'w') do |f|
        f.puts( content )
      end unless File.exists?( file )
    end

    def content_config_yaml
      "# Configuration file for webgen\n# Used to set the parameters of the plugins"
    end

    def content_default_template
      "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.1//EN\" \"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd\">
<html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"{lang:}\">
  <head>
    <title>{title: }</title>
    <link href=\"{relocatable: default.css}\" rel=\"stylesheet\" />
    <meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\" />
  </head>
  <body>
    <div id=\"header\">
      <h1>{title: }</h1>
    </div>

    <div id=\"headerbar\" class=\"bar\">
      <span class=\"left\">Navbar: {navbar: }</span>
      <span class=\"right\">Language: {langbar: }</span>
      <div style=\"clear:both\"></div>
    </div>

    <div id=\"menu\">
      {menu: {subtreeLevel: 4}}
    </div>

    <div id=\"body\">
      {content: }
    </div>

    <div id=\"footer\" class=\"bar\">
      generated with <a href=\"http://webgen.rubyforge.org\"><em><b>webgen</b></em></a> on <b>{date: }</b>
    </div>
  </body>
</html>
"
    end

    def content_default_css
      "
  #all { background-color: #CCCCCC; }

  #header {
    border-bottom: 1px solid black;
    padding: 1ex;
    background-color: #888888;
  }
  #header h1 {
    margin: 0ex;
	font-size: 300%;
	font-style: italic;
	font-weight: normal;
  }

, #headerbar { border-bottom: 1px solid black; }
  #footer { border-top: 1px solid black; }

  #body {
    margin-left: 250px;
    margin-right: 20px;
    padding: 10px;
  }

  #menu {
	float: left;
	width: 230px;
    padding: 20px 0px 0px 2px;
  }

  .bar {
	clear: both;
	padding: 3px;
	text-align: center;
	font-size: 90%;
    background-color: #AAAAAA;
  }

  .left, .right {
    padding: 0px 1em;
  }

  .left {
	float: left;
	text-align: left;
  }

  .right {
	float: right;
	text-align: right;
  }

  /* styling the menu */

  #menu a {
	text-decoration: none;
	font-weight: bold;
	font-size: 130%;
  }

  #menu a:hover {
	text-decoration: underline;
  }

  #menu .webgen-menuitem-selected {
	border-left: 3px solid black;
  }

  #menu ul {
	list-style-type: none;
	padding: 0px;
	margin-left: 10px;
  }

  #menu li > ul {
	font-size: 95%;
  }

  #menu li {
    margin: 0.0em 0px;
    padding: 2px 0px;
    padding-left: 5px;
    border-left: 3px solid #CCCCCC;
  }
"
    end

    def content_index_page
      "---
title: Empty index page
inMenu: true
directoryName: New Website
---
h2. Empty index file

Fill this file with your own data!!!
"
    end

  end


  class CleanCommand < CommandParser::Command

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
      super( 'clean' )
      @all = false
      @ask = false
      options.separator( "Options" )
      options.on( '--all', '-a', "Removes ALL files from the output directory" ) { @all = true }
      options.on( '--interactive', '-i', "Ask for each file" ) { @ask = true }
    end

    def description; "Removes the generated or all files from the output directory"; end

    def usage; "Usage: #{@options.program_name} [global options] clean [options]"; end

    def execute( commandParser, args )
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

    private

  end

  class WebgenCommandParser < CommandParser

    def initialize
      super
      self.options do |opts|
        opts.program_name = "webgen"
        opts.version = Webgen::VERSION
        opts.summary_width = 25
        opts.summary_indent = '  '

        opts.banner = "Usage: webgen [global options] COMMAND [command options]\n#{Webgen::SUMMARY}"

        opts.separator ""
        opts.separator "Global options:"

        opts.on( "--verbosity LEVEL", "-V", Integer, "The verbosity level" ) { |verbosity| Plugin.set_param( 'Logging', 'verbosityLevel', verbosity ) }
        opts.on( "--[no-]logfile", "-L", "Log to file" ) { |logfile| Plugin.set_param( 'Logging', 'logToFile', logfile ) }

        opts.separator ""
      end

      self.add_command( RunWebgenCommand.new, true )
      self.add_command( ShowCommand.new )
      self.add_command( CreateCommand.new )
      self.add_command( CleanCommand.new )
      self.add_command( CommandParser::HelpCommand.new )
      self.add_command( CommandParser::VersionCommand.new )
    end

  end


  class WebgenMain

    def main( cmdOptions )
      Color.colorify if $stdout.isatty && !Config::CONFIG['arch'].include?( 'mswin32' )
      begin
        wcp = WebgenCommandParser.new
        wcp.parse!( ARGV, false )
        Plugin['Configuration'].init_all
        wcp.execute
      rescue CommandParser::InvalidCommandError => e
        puts "Error: invalid command given"
        puts
        wcp.commands['help'].execute( wcp, {} )
      end
    end

  end

end
