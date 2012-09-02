# -*- encoding: utf-8 -*-

require 'cmdparse'
require 'webgen/website'
require 'webgen/version'
require 'webgen/cli/logger'
require 'webgen/cli/utils'
require 'webgen/cli/generate_command'
require 'webgen/cli/show_command'
require 'webgen/cli/bundle_command'

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
  #       self.description = Webgen::CLI::Utils.format_command_desc("Uses the global verbosity level " +
  #         "and outputs additional "information when the level is set to verbose!")
  #       @username = nil
  #       self.options = CmdParse::OptionParserWrapper.new do |opts|
  #         opts.separator "Options:"
  #         opts.on('-u', '--user USER', String,
  #                 *Webgen::CLI::Util.format_option_desc('Specify an additional user name to output')) do |username|
  #           @username = username
  #         end
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
  #   website.ext.cli.add_command(SampleCommand.new)
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

      # Specifies whether verbose output should be used.
      attr_reader :verbose

      # The log level. Default: <tt>Logger::INFO</tt>
      attr_reader :log_level

      # Create a new CommandParser class.
      def initialize
        super(true, true, false)
        @directory = (ENV['WEBGEN_WEBSITE'].to_s.empty? ? Dir.pwd : ENV['WEBGEN_WEBSITE'])
        @log_level = ::Logger::INFO

        self.add_command(CmdParse::VersionCommand.new)
        self.add_command(CmdParse::HelpCommand.new)

        self.program_name = "webgen"
        self.program_version = Webgen::VERSION
        self.options = CmdParse::OptionParserWrapper.new do |opts|
          opts.separator "Global options:"
          opts.on("--directory DIR", "-d", String,
                  *Utils.format_option_desc("The website directory (default: the current directory)")) do |d|
            @directory = d
          end
          opts.on("-c", "--[no-]color",
                  *Utils.format_option_desc("Colorize output (default: #{Webgen::CLI::Utils.use_colors ? "yes" : "no"})")) do |a|
            Webgen::CLI::Utils.use_colors = a
          end
          opts.on("-v", "--[no-]verbose",
                  *Utils.format_option_desc("Verbose output (default: no)")) do |v|
            @verbose = v
          end
          opts.on("-q", "--[no-]quiet",
                  *Utils.format_option_desc("Quiet output (default: no)")) do |v|
            @log_level = (v ? ::Logger::WARN : :Logger::INFO)
          end
          opts.on("--[no-]debug",
                  *Utils.format_option_desc("Enable debugging")) do |v|
            @log_level = (v ? ::Logger::DEBUG : :Logger::INFO)
          end
          opts.on_tail("--version", "-V", "Show webgen version information") do
            main_command.commands['version'].execute([])
          end
        end
        self.add_command(Webgen::CLI::GenerateCommand.new, true)
        self.add_command(Webgen::CLI::ShowCommand.new)
        self.add_command(Webgen::CLI::BundleCommand.new)
      end

      # Utility method for getting the Webgen::Website object.
      def website
        @website ||= Webgen::Website.new(@directory, Webgen::CLI::Logger.new) do |site, before_init|
          if before_init
            site.ext.cli = self
            site.logger.level = @log_level
            site.logger.verbose = @verbose
          end
        end
      end

      # Parse the command line arguments.
      #
      # Once the website directory information is gathered, the Webgen::Website is initialized to
      # allow additional CLI commands to be added by extensions.
      def parse(argv = ARGV)
        super do |level, name|
          if level == 0
            # Create website object/automatically performs initialization; needed so that custom
            # commands can be added
            website
          end
        end
      rescue
        puts "webgen encountered a problem:\n  " + $!.message
        puts $!.backtrace if @log_level == ::Logger::DEBUG
        exit(1)
      end

    end

  end

end
