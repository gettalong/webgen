# -*- encoding: utf-8 -*-

require 'webgen/cli/utils'
require 'webgen/cli/install_bundle_command'
require 'webgen/cli/list_bundle_command'

module Webgen
  module CLI

    # The CLI command for bundle related operations.
    class BundleCommand < CmdParse::Command

      def initialize # :nodoc:
        super('bundle', true, true, false)
        self.short_desc = 'Work with extension bundles'
        self.description = Webgen::CLI::Utils.format_command_desc(<<DESC)
Groups various commands together that are used for working with extension bundles. If
a sub-command is invoked in the context of a webgen website, information about the
website is also included.
DESC
        add_command(ListBundleCommand.new, true)
        add_command(InstallBundleCommand.new)
      end

    end

  end
end
