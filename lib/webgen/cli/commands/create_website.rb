# -*- encoding: utf-8 -*-

require 'webgen/cli/utils'
require 'tmpdir'

module Webgen
  module CLI

    # The CLI command for creating a webgen website.
    class CreateWebsiteCommand < CmdParse::Command

      def initialize # :nodoc:
        super('website', takes_commands: false)
        short_desc('Create a basic webgen website')
        long_desc(<<DESC)
Creates a webgen website at the specified directory. If the --template
option is not used, a basic website is created. Otherwise the template
defines the content of website.

Hint: If the global verbosity option is enabled, the created files are
displayed.
DESC

        @template = nil
        options.on('-t', '--template TEMPLATE', String, "A website template (optional)") do |val|
          @template = val
        end
      end

      def help #:nodoc:
        help_output = super
        templates = command_parser.website.ext.task.data(:create_website)[:templates].keys.sort
        help_output << "Available templates:\n"
        output = if templates.empty?
                   "No templates available"
                 else
                   templates.join(', ')
                 end
        help_output << Utils.format(output, command_parser.help_line_width - command_parser.help_indent, 
                                    command_parser.help_indent, true).join("\n")
      end

      def execute(dir) # :nodoc:
        Webgen::Website.new(dir, Webgen::CLI::Logger.new) do |website|
          website.logger.verbose = command_parser.verbose
          website.config['website.tmpdir'] = Dir.tmpdir
        end.execute_task(:create_website, @template)
        puts "Created a new webgen website in <#{dir}>" + (@template ? " using the '#{@template}' template" : '')
      rescue Webgen::Task::CreateWebsite::Error => e
        puts "An error occured while creating the website: #{e.message}"
      end

    end

  end
end
