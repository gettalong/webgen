require 'rbconfig'
require 'fileutils'
require 'cmdparse'
require 'webgen/website'

module Webgen

  class CommandParser < CmdParse::CommandParser

    VERBOSITY_UNUSED = -1

    attr_reader :directory
    attr_reader :website
    attr_reader :verbosity
    attr_reader :config_file

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
      self.add_command( CmdParse::HelpCommand.new )
      self.add_command( CmdParse::VersionCommand.new )
    end

    def param( param, plugin, cur_val )
      if [plugin, param] == ['Core/Configuration', 'loggerLevel'] && @verbosity != VERBOSITY_UNUSED
        [true, @verbosity]
      else
        [false, cur_val]
      end
    end

    def parse( argv = ARGV )
      super do |level, cmd_name|
        if level == 0
          #@config_file = Webgen::WebSite.load_config_file( @directory )
          @website = Webgen::WebSite.new( @directory )
          @website.plugin_manager.configurators << self
          @website.plugin_manager.configurators << FileConfigurator.new( File.join( @directory, 'config.yaml' ) ) #TODO: make creating Fileconfigurator easier (just with directory param)
          @website.load_plugin_infos
          @website.plugin_manager.plugin_infos[%r{^Cli/Commands/}].each do |name, info|
            self.add_command( @website.plugin_manager[name] )
          end
        end
      end
    end

  end


  # Main program for the webgen CLI.
  def self.cli_main
    cmdparser = CommandParser.new
    cmdparser.parse
  end

end
