# -*- encoding: utf-8 -*-

require 'webgen/cli/utils'
require 'rubygems/dependency_installer'

module Webgen
  module CLI

    # The CLI command for installing extension bundles.
    class InstallCommand < CmdParse::Command

      def initialize # :nodoc:
        super('install', takes_commands: false)
        short_desc('Install an extension bundle')
        long_desc(<<DESC)
Installs an extension bundle via Rubygems. You can either provide the name
of a webgen extension bundle, the name of a Rubygem or a local file name.
DESC
      end

      def execute(name) # :nodoc:
        name = "webgen-#{name}-bundle" unless name =~ /\.gem$/ || name =~ /webgen-.*-bundle/

        inst = Gem::DependencyInstaller.new(:domain => :both, :force => false)
        inst.install(name)
        puts "Installed #{name}"
      end

    end

  end
end
