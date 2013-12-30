# -*- encoding: utf-8 -*-

require 'cmdparse'
require 'yaml'
require 'webgen/website'
require 'webgen/version'
require 'webgen/cli/logger'
require 'webgen/cli/utils'
require 'webgen/cli/commands/generate'
require 'webgen/cli/commands/show'
require 'webgen/cli/commands/create'
require 'webgen/cli/commands/install'

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

      # This error is thrown when an invalid configuration option is encountered.
      class ConfigurationOptionError < CmdParse::ParseError
        reason 'Problem with configuration option'
      end


      # The website directory. Default: the value of the WEBGEN_WEBSITE environment variable or the
      # current working directory.
      #
      # *Note*: Only available after the #website method has been called (which is always the case
      # when a command is executed).
      attr_reader :directory

      # Specifies whether verbose output should be used.
      attr_reader :verbose

      # The log level. Default: Logger::INFO
      attr_reader :log_level

      # Create a new CommandParser class.
      def initialize
        super(false, true, false)
        @directory = nil
        @verbose = false
        @do_search = false
        @log_level = ::Logger::INFO
        @config_options = {}

        self.add_command(CmdParse::VersionCommand.new)
        self.add_command(CmdParse::HelpCommand.new)

        self.program_name = "webgen"
        self.program_version = Webgen::VERSION
        self.options = CmdParse::OptionParserWrapper.new do |opts|
          opts.separator "Global options:"
          opts.on("--directory DIR", "-d", String,
                  *Utils.format_option_desc("The website directory to use")) do |d|
            @directory = d
          end
          opts.on("--search-dirs", "-s",
                  *Utils.format_option_desc("Search parent directories for website directory")) do |s|
            @do_search = s
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
          opts.on("-n", "--[no-]dry-run",
                  *Utils.format_option_desc("Do a dry run, i.e. don't actually write anything (default: no)")) do |v|
            @config_options['website.dry_run'] = v
          end
          opts.on("-o", "--option CONFIG_OPTION", String,
                  *Utils.format_option_desc("Specify a simple configuration option (key=value)")) do |v|
            k, v = v.split('=')
            begin
              @config_options[k.to_s] = YAML.load(v.to_s)
            rescue YAML::SyntaxError
              raise ConfigurationOptionError.new("Couldn't parse value for '#{k}': #{$!}")
            end
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
        self.add_command(Webgen::CLI::CreateCommand.new)
        self.add_command(Webgen::CLI::InstallCommand.new)
      end

      # Utility method for getting the Webgen::Website object.
      #
      # Returns a new website object (not an already created one) if +force_new+ is set to +true+.
      def website(force_new = false)
        return @website if defined?(@website) && !force_new

        @directory = ENV['WEBGEN_WEBSITE'] if @directory.nil? && !ENV['WEBGEN_WEBSITE'].to_s.empty?
        if @directory.nil? && @do_search
          dir = Dir.pwd
          file_missing = nil
          dir = File.dirname(dir) while dir != '/' && (file_missing = !File.exist?(File.join(dir, Webgen::Website::CONFIG_FILENAME)))
          @directory = dir if !file_missing
        end
        @directory = Dir.pwd if @directory.nil?
        @website = Webgen::Website.new(@directory, Webgen::CLI::Logger.new) do |site, before_init|
          if before_init
            site.ext.cli = self
            site.logger.level = @log_level
            site.logger.verbose = @verbose
            site.logger.prefix = '[DRY-RUN] ' if @config_options['website.dry_run']
          else
            @config_options.each do |k, v|
              if site.config.option?(k)
                site.config[k] = v
              else
                raise ConfigurationOptionError.new("Unknown option '#{k}'")
              end
            end
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
            begin
              website
            rescue Webgen::BundleLoadError
            end
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
