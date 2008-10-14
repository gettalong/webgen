require 'cmdparse'
require 'webgen/website'
require 'webgen/version'

module Webgen

  # Namespace for all classes that act as CLI commands.
  #
  # = Implementing a CLI command
  #
  # Each CLI command class needs to be put into this module and has to end with +Command+, otherwise
  # it is not used. A CLI command is an extension that can be invoked from the webgen command and
  # thus needs to be derived from CmdParse::Command. For detailed information on this class and the
  # whole cmdparse package have a look at http://cmdparse.rubyforge.org!
  #
  # = Sample CLI command
  #
  # Here is a sample CLI command extension:
  #
  #   require 'webgen/cli'
  #
  #   class Webgen::CLI::SampleCommand < CmdParse::Command
  #
  #     def initialize
  #       super('sample', false)
  #       self.short_desc = "This sample command just outputs its parameters"
  #       self.description = Utils.format("Uses the global verbosity level and outputs additional " +
  #         "information when the level is set to verbose!")
  #       @username = nil
  #       self.options = CmdParse::OptionParserWrapper.new do |opts|
  #         opts.separator "Options:"
  #         opts.on('-u', '--user USER', String,
  #           'Specify an additional user name to output') {|@username|}
  #       end
  #     end
  #
  #     def execute(args)
  #       if args.length == 0
  #         raise OptionParser::MissingArgument.new('ARG1 [ARG2 ...]')
  #       else
  #         puts "Command line arguments:"
  #         args.each {|arg| puts arg}
  #         if commandparser.verbosity == :verbose
  #           puts "Yeah, some additional information is always cool!"
  #         end
  #         puts "The entered username: #{@username}" if @username
  #       end
  #     end
  #
  #   end
  #
  # Note the use of Utils.format in the initialize method so that the long text gets wrapped
  # correctly! The Utils class provides some other useful methods, too!
  #
  # For information about which attributes are available on the webgen command parser instance have
  # a look at Webgen::CLI::CommandParser!
  module CLI

    autoload :RunCommand, 'webgen/cli/run_command'
    autoload :CreateCommand, 'webgen/cli/create_command'
    autoload :WebguiCommand, 'webgen/cli/webgui_command'

    autoload :Utils, 'webgen/cli/utils'


    # This is the command parser class used for handling the webgen command line interface. After
    # creating an instance, the inherited #parse method can be used for parsing the command line
    # arguments and executing the requested command.
    class CommandParser < CmdParse::CommandParser

      # The website directory. Default: the current working directory.
      attr_reader :directory

      # The verbosity level. Default: <tt>:normal</tt>
      attr_reader :verbosity

      # The log level. Default: <tt>Logger::WARN</tt>
      attr_reader :log_level

      def initialize # :nodoc:
        super(true)
        @directory = Dir.pwd
        @verbosity = :normal
        @log_level = ::Logger::WARN
        @log_filter = nil

        self.program_name = "webgen"
        self.program_version = Webgen::VERSION
        self.options = CmdParse::OptionParserWrapper.new do |opts|
          opts.separator "Global options:"
          opts.on("--directory DIR", "-d", String, "The website directory (default: the current directory)") {|p| @directory = p}
          opts.on("--verbose", "-v", "Print more output") { @verbosity = :verbose }
          opts.on("--quiet", "-q", "No output") { @verbosity = :quiet }
          opts.on("--log-level LEVEL", "-l", Integer, "The logging level (0..debug, 3..error)") {|p| @log_level = p}
          opts.on("--log-filter", "-f", Regexp, 'Filter for logging events') {|p| @log_filter = p}
        end
        self.add_command(CmdParse::HelpCommand.new)
        self.add_command(CmdParse::VersionCommand.new)
        Webgen::CLI.constants.select {|c| c =~ /.+Command$/ }.each do |c|
          self.add_command(Webgen::CLI.const_get(c).new, (c.to_s == 'RunCommand' ? true : false))
        end
      end

      # Utility method for sub-commands to create the correct Webgen::Website object.
      def create_website
        website = Webgen::Website.new(@directory) do |config|
          config['logger.mask'] = @log_filter
        end
        website.logger.level = @log_level
        website.logger.verbosity = @verbosity
        website
      end

    end

  end

end
