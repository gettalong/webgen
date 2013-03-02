# -*- encoding: utf-8 -*-

require 'webgen/cli/utils'

module Webgen
  module CLI

    # The CLI command for generating a webgen website.
    class GenerateCommand < CmdParse::Command

      def initialize # :nodoc:
        super('generate', false, false, false)
        self.short_desc = 'Generate the webgen website'
        self.description = Webgen::CLI::Utils.format_command_desc("This command is executed by default when " +
                                                                  "no other command was specified.")
      end

      def execute(args) # :nodoc:
        commandparser.website.execute_task(:generate_website)
      end

    end

  end
end
