# -*- encoding: utf-8 -*-

require 'webgen/cli/utils'

module Webgen
  module CLI

    # The CLI command for showing available extension.
    class ShowExtensionsCommand < CmdParse::Command

      def initialize # :nodoc:
        super('extensions', takes_commands: false)
        short_desc('Show available extensions')
        long_desc(<<DESC)
Shows all available extensions and additional information about them, e.g. a
short summary of the functionality or the extension bundle it is defined in.

If an argument is given, only those extensions that have the argument in their
name are displayed.

Hint: The global verbosity option enables additional output.
DESC
        options.on("-b NAME", "--bundle NAME", String, "Only show extensions of this bundle") do |bundle|
          @bundle = bundle
        end
        @bundle = nil
      end

      def execute(selector = '') # :nodoc:
        command_parser.website.ext.bundle_infos.extensions.select do |n, d|
          n.include?(selector) && (@bundle.nil? || d['bundle'] == @bundle)
        end.sort.each do |name, data|
          format_extension_info(name, data, !selector.empty?)
        end
      end

      def format_extension_info(name, data, has_selector)
        author = (!data['author'] || data['author'].empty? ? 'unknown' : data['author'])

        indentation = (has_selector ? 0 : name.count('.')*2)
        puts(" "*indentation + Utils.light(Utils.blue(name)))
        if command_parser.verbose
          print(" "*(indentation + 2) + "Bundle:  ")
          puts(Utils.format(data['bundle'], 78, indentation + 11, false))
          print(" "*(indentation + 2) + "Author:  ")
          puts(Utils.format(author, 78, indentation + 11, false))
          print(" "*(indentation + 2) + "Summary: ")
          puts(Utils.format(data['summary'], 78, indentation + 11, false))
        else
          puts(Utils.format(data['summary'], 78, indentation + 2, true).join("\n"))
        end
        puts
      end
      private :format_extension_info

    end

  end
end
