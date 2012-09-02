# -*- encoding: utf-8 -*-

require 'webgen/cli/utils'

module Webgen
  module CLI

    # The CLI command for showing available extension.
    class ShowExtensionsCommand < CmdParse::Command

      def initialize # :nodoc:
        super('extensions', false, false, true)
        self.short_desc = 'Show available extensions'
        self.description = Utils.format_command_desc(<<DESC)
Shows all available extensions and additional information about them, e.g. a
short summary of the functionality or the extension bundle it is defined in.

If an argument is given, only those extensions that have the argument in their
name are displayed.

Hint: The global verbosity option enables additional output.
DESC
        self.options = CmdParse::OptionParserWrapper.new do |opts|
          opts.separator "Options:"
          opts.on("-b NAME", "--bundle NAME", String,
                  *Utils.format_option_desc("Only show extensions of this bundle")) do |bundle|
            @bundle = bundle
          end
        end
        @bundle = nil
      end

      def execute(args)
        exts = {}
        commandparser.website.ext.bundles.each do |bundle, info_file|
          next if info_file.nil? || (@bundle && @bundle != bundle)
          infos = YAML.load(File.read(info_file))
          next unless infos['extensions']
          infos['extensions'].each do |n, d|
            d['bundle'] = bundle
            d['author'] ||= infos['author']
          end
          exts.update(infos['extensions'])
        end

        selector = args.first.to_s
        exts.select {|n, d| n.include?(selector)}.sort.each do |name, data|
          format_extension_info(name, data, !selector.empty?)
        end
      end

      def format_extension_info(name, data, has_selector)
        author = (!data['author'] || data['author'].empty? ? 'unknown' : data['author'])

        indentation = (has_selector ? 0 : name.count('.')*2)
        puts(" "*indentation + Utils.light(Utils.blue(name)))
        if commandparser.verbose
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
