#
#--
#
# $Id: cli.rb 601 2007-02-14 21:20:44Z thomas $
#
# webgen: template based static website generator
# Copyright (C) 2004 Thomas Leitner
#
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU
# General Public License as published by the Free Software Foundation; either version 2 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
# even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with this program; if not,
# write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#
#++
#

require 'rbconfig'
require 'fileutils'
require 'cmdparse'
require 'webgen/website'

module Webgen

  class CommandParser < CmdParse::CommandParser

    VERBOSITY_UNUSED = -1

    attr_reader :directory
    attr_reader :website
    attr_reader :verbosity
    attr_reader :config_file

    def initialize
      super( true )
      @directory = Dir.pwd
      @verbosity = VERBOSITY_UNUSED

      self.program_name = "webgen"
      self.program_version = Webgen::VERSION
      self.options = CmdParse::OptionParserWrapper.new do |opts|
        opts.separator "Global options:"
        opts.on( "--directory DIR", "-d", String, "The website directory, if none specified, current directory is used." ) {|@directory|}
        opts.on( "--verbosity LEVEL", "-V", Integer, "The verbosity level (0-3)" ) {|@verbosity|}
      end
      self.add_command( CmdParse::HelpCommand.new )
      self.add_command( CmdParse::VersionCommand.new )

    end

    def param_for_plugin( plugin_name, param )
      if [plugin_name, param] == ['Core/Configuration', 'loggerLevel'] && @verbosity != VERBOSITY_UNUSED
        @verbosity
      elsif @config_file
        @config_file.param_for_plugin( plugin_name, param )
      else
        Webgen::PluginParamValueNotFound
      end
    end

    def parse( argv = ARGV )
      super do |level, cmd_name|
        if level == 0
          #@config_file = Webgen::WebSite.load_config_file( @directory )
          @website = Webgen::WebSite.new( @directory )
          @website.plugin_manager.configurators << self
          @website.load_plugin_infos
          @website.plugin_manager.plugin_infos[%r{^Cli/Commands/}].each do |name, info|
            self.add_command( @website.plugin_manager[name] )
          end
        end
      end
    end

  end


  # Main program for the webgen CLI.
  def self.cli_main
    cmdparser = CommandParser.new
    cmdparser.parse
  end

end
