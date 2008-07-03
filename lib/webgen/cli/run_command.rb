require 'webgen/cli'

module Webgen::CLI

  # The CLI command for rendering a webgen website.
  class RunCommand < CmdParse::Command

    def initialize # :nodoc:
      super('render', false)
      self.short_desc = 'Render the webgen website'
    end

    # Render the website.
    def execute(args)
      commandparser.create_website.render
    end

  end

end
