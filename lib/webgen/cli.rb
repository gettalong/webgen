# -*- encoding: utf-8 -*-

require 'cmdparse'
require 'webgen/website'
require 'webgen/version'
require 'webgen/cli/logger'
require 'webgen/cli/utils'
require 'webgen/cli/run_command'

module Webgen

  # Namespace for all classes that act as CLI commands.
  #
  # == Implementing a CLI command
  #
  # A CLI command is an extension that can be invoked from the webgen CLI and thus needs to be
  # derived from CmdParse::Command. For detailed information on this class and the whole cmdparse
  # package have a look at http://cmdparse.rubyforge.org!
  #
  # == Sample CLI command extension
  #
  # Here is a sample CLI command extension:
  #
  #   class SampleCommand < CmdParse::Command
  #
  #     def initialize
  #       super('sample', false)
  #       self.short_desc = "This sample command just outputs its parameters"
  #       self.description = Webgen::CLI::Utils.format("Uses the global verbosity level and outputs additional " +
  #         "information when the level is set to verbose!")
  #       @username = nil
  #       self.options = CmdParse::OptionParserWrapper.new do |opts|
  #         opts.separator "Options:"
  #         opts.on('-u', '--user USER', String,
  #           'Specify an additional user name to output') {|username| @username = username}
  #       end
  #     end
  #
  #     def execute(args)
  #       if args.length == 0
  #         raise OptionParser::MissingArgument.new('ARG1 [ARG2 ...]')
  #       else
  #         puts "Command line arguments:"
  #         args.each {|arg| puts arg}
  #         if commandparser.log_level <= 1
  #           puts "Some debug information here"
  #         end
  #         puts "The entered username: #{@username}" if @username
  #       end
  #     end
  #
  #   end
  #
  #   website.ext.cli_commands << SampleCommand.new
  #
  # Note the use of Webgen::CLI::Utils.format in the initialize method so that the long text gets
  # wrapped correctly! The Utils class provides some other useful methods, too!
  #
  module CLI

    # This is the command parser class used for handling the webgen command line interface.
    #
    # After creating an instance, the #parse method can be used for parsing the command line
    # arguments and executing the requested command.
    class CommandParser < CmdParse::CommandParser

      # The website directory. Default: the value of the WEBGEN_WEBSITE environment variable or the
      # current working directory.
      attr_reader :directory

      # The log level. Default: <tt>Logger::INFO</tt>
      attr_reader :log_level

      # Create a new CommandParser class.
      def initialize
        super(true)
        @directory = (ENV['WEBGEN_WEBSITE'].to_s.empty? ? Dir.pwd : ENV['WEBGEN_WEBSITE'])
        @log_level = ::Logger::INFO

        self.program_name = "webgen"
        self.program_version = Webgen::VERSION
        self.options = CmdParse::OptionParserWrapper.new do |opts|
          opts.separator "Global options:"
          opts.on("--directory DIR", "-d", String, "The website directory (default: the current directory)") {|p| @directory = p}
          opts.on("--log-level LEVEL", "-l", Integer, "The logging level (default=1; 0=debug, 1=info, 2=warning, 3=error)") {|p| @log_level = p}
        end
        self.add_command(CmdParse::HelpCommand.new)
        self.add_command(CmdParse::VersionCommand.new)
        self.add_command(Webgen::CLI::RunCommand.new, true)
      end

      # Utility method for getting the Webgen::Website object.
      def website
        @website ||= Webgen::Website.new(@directory, Webgen::CLI::Logger.new) do |site, before_init|
          if before_init
            site.ext.cli_commands = []
            site.logger.level = @log_level
          end
        end
      end

      # Parse the command line arguments.
      #
      # Once the website directory information is gathered, the Webgen::Website is initialized to
      # add additional CLI commands specified by extensions.
      def parse(argv = ARGV)
        super do |level, name|
          website.ext.cli_commands.each {|cmd| self.add_command(cmd)} if level == 0
        end
      end

    end

  end

end
