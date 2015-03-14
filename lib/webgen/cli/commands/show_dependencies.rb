# -*- encoding: utf-8 -*-

require 'webgen/cli/utils'

module Webgen
  module CLI

    # The CLI command for showing dependencies (tracked items) of paths.
    class ShowDependenciesCommand < CmdParse::Command

      def initialize # :nodoc:
        super('deps', takes_commands: false)
        short_desc('Show dependencies for all paths')
        long_desc(<<DESC)
Shows the dependencies (i.e. tracked items) for each path. This is only useful
after webgen has generated the website at least once so that this information
is available.

If an argument is given, only those paths that have the argument in their name
are displayed with their dependencies.

Hint: The global verbosity option enables additional output.
DESC
      end

      def execute(selector = nil) # :nodoc:
        data = command_parser.website.ext.item_tracker.cached_items(command_parser.verbose)
        if data.empty?
          puts "No data available, you need to generate the website first!"
          return
        end

        data.select! {|alcn, _| alcn.include?(selector) } if selector
        data.sort.each do |alcn, items|
          if items.length > 0 || command_parser.verbose
            puts("#{Utils.light(Utils.blue(alcn))}: ")
            items.each {|d| puts("  #{[d].flatten.join("\n    ")}")}
          end
        end
      end

    end

  end
end
