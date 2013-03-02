# -*- encoding: utf-8 -*-

require 'webgen/cli/utils'
require 'fileutils'
require 'erb'

module Webgen
  module CLI

    # The CLI command for creating a new extension bundle.
    class CreateBundleCommand < CmdParse::Command

      def initialize # :nodoc:
        super('bundle', false, false, true)
        self.short_desc = 'Create an extension bundle'
        self.description = Utils.format_command_desc(<<DESC)
Creates a new extension bundle. This command can either create a local bundle in the
website's ext/ directory or a bundle that can be distributed via Rubygems. In the
latter case you can optionally specify the directory under which the bundle should
be created.
DESC
        self.options = CmdParse::OptionParserWrapper.new do |opts|
          opts.separator "Options:"
          opts.on("-d", "--distribution-format",
                  *Utils.format_option_desc("Create the bundle in distribution format")) do
            @type = :gem
          end
        end
        @type = :local
      end

      def usage # :nodoc:
        "Usage: webgen [global options] create bundle [options] BUNDLE_NAME [DIRECTORY]"
      end

      def execute(args) # :nodoc:
        bundle_name = args.shift
        raise "The argument NAME is mandatory" if bundle_name.to_s.empty?
        directory = args.shift || bundle_name
        commandparser.website.execute_task(:create_bundle, bundle_name, @type, directory)
      end

    end

  end
end
