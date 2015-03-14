# -*- encoding: utf-8 -*-

require 'webgen/cli/utils'

module Webgen
  module CLI

    # The CLI command for showing all available options.
    class ShowConfigCommand < CmdParse::Command

      def initialize # :nodoc:
        super('config', takes_commands: false)
        short_desc('Show available configuration options')
        long_desc(<<DESC)
Shows all available configuration options. The option name and default value as
well as the currently used value are displayed.

If an argument is given, only those options that have the argument in their name
are displayed.

The global verbosity flag enables all optional display parts.

Hint: A debug message will appear at the top of the output if this command is run
in the context of a website, there are unknown configuration options in the
configuration file and the log level is set to debug.
DESC
        options do |opts|
          opts.on("-m", "--modified", "Show modified configuration options only") do |v|
            @modified = true
          end
          opts.on("-d", "--[no-]descriptions", "Show descriptions") do |d|
            @show_description = d
          end
          opts.on("-s", "--[no-]syntax", "Show the syntax") do |s|
            @show_syntax = s
          end
          opts.on("-e", "--[no-]example", "Show usage examples") do |e|
            @show_examples = e
          end
        end
        @modified = false
        @show_description = false
        @show_syntax = false
        @show_examples = false
      end

      def execute(selector = '') # :nodoc:
        @show_description = @show_syntax = @show_examples = true if command_parser.verbose

        config = command_parser.website.config
        descriptions = command_parser.website.ext.bundle_infos.options
        config.options.select do |n, d|
          n.include?(selector) && (!@modified || config[n] != d.default)
        end.sort.each do |name, data|
          format_config_option(name, data, config[name], descriptions[name])
        end
      end

      def format_config_option(name, data, cur_val, meta_info)
        print("#{Utils.light(Utils.blue(name))}: ")
        if cur_val != data.default
          puts(Utils.green(cur_val.to_s) + " (default: #{data.default})")
        else
          puts(cur_val.inspect)
        end

        puts(Utils.format(meta_info['summary'], 78, 2, true).join("\n") + "\n\n") if @show_description
        if @show_syntax
          puts(Utils.format("Syntax:", 78, 2, true).join("\n"))
          puts(Utils.format(meta_info['syntax'], 78, 4, true).join("\n") + "\n\n")
        end
        if @show_examples
          meta_info['example'].each do |n,v|
            puts(Utils.format("Example for usage in #{n}:", 78, 2, true).join("\n"))
            puts(Utils.format(v, 78, 4, true).join("\n") + "\n\n")
          end
        end
      end
      private :format_config_option

    end

  end
end
