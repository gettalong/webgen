# -*- encoding: utf-8 -*-

require 'webgen/cli/utils'
require 'rubygems/dependency_installer'

module Webgen
  module CLI

    # The CLI command for installing extension bundles.
    class InstallBundleCommand < CmdParse::Command

      def initialize # :nodoc:
        super('install', false, false, true)
        self.short_desc = 'Install an extension bundle'
        self.description = Utils.format_command_desc(<<DESC)
Installs an extension bundle via Rubygems. You can either provide the name
of a webgen extension bundle, the name of a Rubygem or a local file name.
DESC
      end

      def execute(args)
        raise CmdParse::InvalidArgumentError.new("Bundle name needed but none given") if args.length == 0
        name = args.first
        name = "webgen-#{name}-bundle" unless name =~ /\.gem$/ || name =~ /webgen-.*-bundle/

        inst = Gem::DependencyInstaller.new(:domain => :both, :force => false)
        inst.install(name)
        puts "Installed #{name}"
      end

    end

  end
end
