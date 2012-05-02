# -*- encoding: utf-8 -*-

module Webgen
  module CLI

    # The CLI command for generating a webgen website.
    class GenerateCommand < CmdParse::Command

      def initialize # :nodoc:
        super('generate', false)
        self.short_desc = 'Generate the webgen website'
      end

      # Render the website.
      def execute(args)
        commandparser.website.generate
      end

    end

  end
end
