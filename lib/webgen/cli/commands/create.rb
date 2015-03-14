# -*- encoding: utf-8 -*-

require 'webgen/cli/utils'
require 'webgen/cli/commands/create_website'
require 'webgen/cli/commands/create_bundle'

module Webgen
  module CLI

    # The CLI command for creating various products, like a basic website or an extension bundle.
    class CreateCommand < CmdParse::Command

      def initialize # :nodoc:
        super('create')
        short_desc('Create a website or an extension bundle')
        long_desc("Groups various commands together that are used for creating products, like a " +
                  "website or an extension bundle")
        add_command(CreateWebsiteCommand.new)
        add_command(CreateBundleCommand.new)
      end

    end

  end
end
