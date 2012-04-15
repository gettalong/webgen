# -*- encoding: utf-8 -*-

module Webgen
  module CLI

    # The CLI command for rendering a webgen website.
    class RenderCommand < CmdParse::Command

      def initialize # :nodoc:
        super('render', false)
        self.short_desc = 'Render the webgen website'
      end

      # Render the website.
      def execute(args)
        commandparser.website.render
      end

    end

  end
end
