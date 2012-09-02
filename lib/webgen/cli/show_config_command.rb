# -*- encoding: utf-8 -*-

require 'webgen/cli/utils'

module Webgen
  module CLI

    # The CLI command for showing all available options.
    class ShowConfigCommand < CmdParse::Command

      def initialize # :nodoc:
        super('config', false, false, true)
        self.short_desc = 'Show available configuration options'
        self.description = Utils.format_command_desc(<<DESC)
Shows all available configuration options. The option name and default value as
well as the currently used value are displayed.

If an argument is given, only those options that have the argument in their name
are displayed.

Hint: A debug message will appear at the top of the output if this command is run
in the context of a website, there are unknown configuration options in the
configuration file and the log level is set to debug.
DESC
        self.options = CmdParse::OptionParserWrapper.new do |opts|
          opts.separator "Options:"
          opts.on("-m", "--modified",
                  *Utils.format_option_desc("Show modified configuration options only")) do |v|
            @modified = true
          end
          opts.on("-v", "--[no-]verbose",
                  *Utils.format_option_desc("Verbose output (e.g. option descriptions)")) do |v|
            @verbose = v
          end
        end
        @modified = false
        @unknown = true
        @verbose = false
      end

      def execute(args)
        config = commandparser.website.config
        selector = args.first.to_s
        config.options.select do |n, d|
          n.include?(selector) && (!@modified || config[n] != d.default)
        end.sort.each do |name, data|
          format_config_option(name, data, config[name])
        end
      end

      def format_config_option(name, data, cur_val)
        print("#{Utils.light(Utils.blue(name))}: ")
        if cur_val != data.default
          puts(Utils.green(cur_val.to_s) + " (default: #{data.default})")
        else
          puts(cur_val.inspect)
        end
        puts(Utils.format(data.description, 78, 2, true).join("\n") + "\n\n") if @verbose
      end
      private :format_config_option

    end

  end
end
