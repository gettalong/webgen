# -*- encoding: utf-8 -*-

require 'webgen/cli/utils'
require 'webgen/cli/commands/show_extensions'
require 'webgen/cli/commands/show_config'
require 'webgen/cli/commands/show_dependencies'
require 'webgen/cli/commands/show_tree'
require 'webgen/cli/commands/show_bundles'

module Webgen
  module CLI

    # The CLI command for showing various information about webgen itself or a webgen website.
    class ShowCommand < CmdParse::Command

      def initialize # :nodoc:
        super('show', true, true, false)
        self.short_desc = 'Show various information about webgen or a website'
        self.description = Webgen::CLI::Utils.format_command_desc(<<DESC)
Groups various commands together that are used for showing information about webgen,
like available extensions or configuration options. If a sub-command is invoked in the
context of a webgen website, information about the website is also included.
DESC
        add_command(ShowConfigCommand.new)
        add_command(ShowExtensionsCommand.new)
        add_command(ShowDependenciesCommand.new)
        add_command(ShowTreeCommand.new)
        add_command(ShowBundlesCommand.new)
      end

    end

  end
end
