# -*- encoding: utf-8 -*-

require 'webgen/cli/utils'
require 'fileutils'
require 'erb'

module Webgen
  module CLI

    # The CLI command for creating a new extension bundle.
    class CreateBundleCommand < CmdParse::Command

      def initialize # :nodoc:
        super('bundle', takes_commands: false)
        short_desc('Create an extension bundle')
        long_desc(<<DESC)
Creates a new extension bundle. This command can either create a local bundle in the
website's ext/ directory or a bundle that can be distributed via Rubygems. In the
latter case you can optionally specify the directory under which the bundle should
be created.
DESC
        options.on("-d", "--distribution-format", "Create the bundle in distribution format") do
          @type = :gem
        end
        @type = :local
      end

      def execute(bundle_name, directory = nil) # :nodoc:
        directory ||= bundle_name
        command_parser.website.execute_task(:create_bundle, bundle_name, @type, directory)
      end

    end

  end
end
