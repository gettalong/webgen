# -*- encoding: utf-8 -*-

require 'webgen/cli/utils'
require 'tmpdir'

module Webgen
  module CLI

    # The CLI command for creating a webgen website.
    class CreateWebsiteCommand < CmdParse::Command

      def initialize # :nodoc:
        super('website', false)
        self.short_desc = 'Create a basic webgen website'
        self.description = Utils.format_command_desc(<<DESC)
Creates a webgen website at the specified directory. If the --template
option is not used, a basic website is created. Otherwise the template
defines the content of website.

Hint: If the global verbosity option is enabled, the created files are
displayed.
DESC

        @template = nil
        self.options = CmdParse::OptionParserWrapper.new do |opts|
          opts.separator "Options:"
          opts.on('-t', '--template TEMPLATE', String, "A website template (optional)") do |val|
            @template = val
          end
          opts.separator ""
          opts.separator "Arguments:"
          opts.separator opts.summary_indent + "DIR: the directory in which the website should be created"
        end
      end

      def show_help #:nodoc:
        super
        templates = commandparser.website.ext.task.data(:create_website)[:templates].keys.sort
        puts "Available templates:"
        output = if templates.empty?
                   "No templates available"
                 else
                   templates.join(', ')
                 end
        puts Utils.format(output, Utils::DEFAULT_WIDTH - 4, 4, true).join("\n")
      end

      def execute(args) # :nodoc:
        raise OptionParser::MissingArgument.new('DIR') if args.length == 0
        Webgen::Website.new(args[0], Webgen::CLI::Logger.new) do |website|
          website.logger.verbose = commandparser.verbose
          website.config['website.tmpdir'] = Dir.tmpdir
        end.execute_task(:create_website, @template)
        puts "Created a new webgen website in <#{args[0]}>" + (@template ? " using the '#{@template}' template" : '')
      rescue Webgen::Task::CreateWebsite::Error => e
        puts "An error occured while creating the website: #{e.message}"
      end

    end

  end
end
