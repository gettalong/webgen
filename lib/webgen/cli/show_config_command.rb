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
DESC
        self.options = CmdParse::OptionParserWrapper.new do |opts|
          opts.separator "Options:"
          opts.on("-v", "--[no-]verbose",
                  *Utils.format_option_desc("Verbose output (e.g. option descriptions)")) do |v|
            @verbose = v
          end
        end
        @verbose = false
      end

      def execute(args)
        config = commandparser.website.config
        selector = args.first.to_s
        config.options.select {|n, d| n.include?(selector)}.sort.each do |name, data|
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
