# -*- encoding: utf-8 -*-

require 'webgen/cli/utils'
require 'fileutils'
require 'erb'

module Webgen
  module CLI

    # The CLI command for creating a new extension bundle.
    class CreateBundleCommand < CmdParse::Command

      TEMPLATE_DIR = 'bundle_template_files'

      def initialize # :nodoc:
        super('create', false, false, true)
        self.short_desc = 'Create an extension bundle'
        self.description = Utils.format_command_desc(<<DESC)
Creates a new extension bundle. This command can either create a bundle in the
website's ext/ directory or a bundle that can be distributed via Rubygems. In the
latter case you can optionally specify the directory under which the bundle should
be created.
DESC
        self.options = CmdParse::OptionParserWrapper.new do |opts|
          opts.separator "Options:"
          opts.on("-d", "--distribution-format",
                  *Utils.format_option_desc("Create the bundle in distribution format")) do
            @format = :gem
          end
        end
        @format = :local
      end

      def usage
        "Usage: webgen [global options] bundle create [options] BUNDLE_NAME [DIRECTORY]"
      end

      def execute(args)
        bundle_name = args.shift
        raise "The argument NAME is mandatory" if bundle_name.to_s.empty?

        dir = if @format == :gem
                create_distribution_bundle((args.length == 0 ? bundle_name : args.first), bundle_name)
              else
                create_local_bundle(bundle_name)
              end
        puts "Bundle '#{bundle_name}' created at '#{dir}'"
      end

      def create_distribution_bundle(directory, bundle_name)
        bundle_dir = File.join(directory, 'lib', 'webgen', 'bundle', bundle_name)

        create_directory(directory)
        create_directory(bundle_dir)
        create_file(File.join(directory, 'Rakefile'), 'Rakefile.erb', bundle_name)
        create_file(File.join(directory, 'README.md'), 'README.md.erb', bundle_name)
        create_file(File.join(bundle_dir, 'info.yaml'), 'info.yaml.erb', bundle_name)
        create_file(File.join(bundle_dir, 'init.rb'), 'init.rb.erb', bundle_name)
        directory
      end

      def create_local_bundle(bundle_name)
        bundle_dir =  File.join(commandparser.website.directory, 'ext', bundle_name)

        create_directory(bundle_dir)
        create_file(File.join(bundle_dir, 'info.yaml'), 'info.yaml.erb', bundle_name)
        create_file(File.join(bundle_dir, 'init.rb'), 'init.rb.erb', bundle_name)
        bundle_dir
      end

      def create_directory(dir)
        raise "The directory '#{dir}' does already exist" if File.exist?(dir)
        FileUtils.mkdir_p(dir)
      end
      private :create_directory

      def create_file(dest, source, bundle_name)
        File.open(dest, 'w+') do |f|
          erb = ERB.new(File.read(File.join(Webgen.data_dir, TEMPLATE_DIR, source)))
          f.write(erb.result(binding))
        end
      end
      private :create_file

    end

  end
end
