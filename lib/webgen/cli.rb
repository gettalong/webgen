require 'cmdparse'
require 'webgen/website'

module Webgen

  # This is the command parser class used for handling the webgen command line interface. All CLI
  # command plugins (see Cli::Commands) are added to this instance.
  class CommandParser < CmdParse::CommandParser

    VERBOSITY_UNUSED = -1

    # The website directory.
    attr_reader :directory

    # The created WebSite instance.
    attr_reader :website

    # The user configured verbosity level. Returns -1 if the user didn't specify a verbosity setting
    # on the command line.
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
          @website = Webgen::WebSite.new( @directory )
          @website.plugin_manager.configurators << FileConfigurator.for_website( @directory ) rescue nil #TODO: notify the user of this
          @website.plugin_manager.configurators << self
          @website.plugin_manager.logger.level = @website.plugin_manager.param( 'loggerLevel', 'Core/Configuration' )
          @website.plugin_manager.plugin_infos[%r{^Cli/Commands/}].each do |name, info|
            main_cmd = @website.plugin_manager.plugin_infos.get( name, 'cli_main_cmd' )
            self.add_command( @website.plugin_manager[name], !main_cmd.nil? )
          end
        end
      end
    end

  end


  # Main program for the webgen CLI.
  def self.cli_main
    CommandParser.new.parse
  end

end
