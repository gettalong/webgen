#
#--
#
# $Id$
#
# webgen: a template based web page generator
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

require 'yaml'
require 'ostruct'
require 'log4r'
require 'log4r/yamlconfigurator'
require 'util/ups'


module Webgen

  Version = "0.2.0"
  Description = "Webgen is a template based web page generator."

  class WebgenConfigurationPlugin < UPS::Plugin

    NAME = "Configuration"
    SHORT_DESC = "Responsible for loading the configuration data"

    attr_accessor :srcDirectory
    attr_accessor :outDirectory
    attr_accessor :verbosityLevel
    attr_accessor :lang
    attr_accessor :configFile

    attr_reader :pluginData
    attr_reader :configParams

    def initialize
      @homeDir = File.dirname( $0 )
      @configFile = 'config.yaml'
      @pluginData = Hash.new
      @configParams = Hash.new
    end


    def parse_config_file
      if File.exists? @configFile
        @pluginData = YAML::load( File.new( @configFile ) )
      end

      @srcDirectory ||= get_config_value( 'Configuration', 'srcDirectory', 'src' )
      @outDirectory ||= get_config_value( 'Configuration', 'outDirectory', 'output' )
      @verbosityLevel ||= get_config_value( 'Configuration', 'verbosityLevel', 3 )
      @lang ||= get_config_value( 'Configuration', 'lang', 'en' )
      Log4r::Outputter['stdout'].level = @verbosityLevel
    end


    def load_file_outputter
      Log4r::YamlConfigurator.load_yaml_string FileOutputterConfiguration
    end


    def get_config_value( pluginName, key, defaultValue )
      value = @pluginData[pluginName][key] if @pluginData.has_key?( pluginName ) && @pluginData[pluginName].has_key?( key )
      value ||= defaultValue
      @configParams[pluginName] ||= Hash.new
      @configParams[pluginName][key] = OpenStruct.new( :name => key, :value => value, :defaultValue => defaultValue )
      value
    end

  end

  UPS::Registry.register_plugin( WebgenConfigurationPlugin )

end


#### Log4r Configuration ####


class Log4r::PatternFormatter
  remove_const(:DirectiveTable)

  # Redefinition of the DirectiveTable to only show the method name in the trace.
  DirectiveTable =  {
    "c" => 'event.name',
    "C" => 'event.fullname',
    "d" => 'format_date',
    "t" => "event.tracer[0][/`.*'/][1..-2]",
    "m" => 'event.data',
    "M" => 'format_object(event.data)',
    "l" => 'LNAMES[event.level]',
    "%" => '"%"'
  }
end


LoggerConfiguration = <<EOF
log4r_config:
  pre_config:
    custom_levels:
      - DEBUG
      - INFO
      - WARN
      - ERROR
    root:
      level: DEBUG

  loggers:
    - name: default
      level: DEBUG
      trace: true
      outputters:
        - stdout

  outputters:
    - type     : StdoutOutputter
      name     : stdout
      level    : WARN
      formatter:
        type        : PatternFormatter
        date_pattern: '%Y-%m-%d %H:%M:%S'
        pattern     : '%d %-5l %-15.15c:%-20.20t > %m'

EOF

FileOutputterConfiguration = <<EOF
log4r_config:
  loggers: {}

  outputters:
    - type        : FileOutputter
      name        : logfile
      level       : DEBUG
      trunc       : 'false'
      filename    : 'webgen.log'
      formatter   :
        type        : PatternFormatter
        date_pattern: '%Y-%m-%d %H:%M:%S'
        pattern     : '%d %-5l %-15.15c:%-20.20t > %m'

EOF
Log4r::YamlConfigurator.load_yaml_string LoggerConfiguration


class Object

  # Returns the logger for the class of the object. If the logger does not exist, the logger is
  # created using the name of the class.
  def logger
    if @logger.nil?
      @logger = Log4r::Logger[self.class.name]
      if @logger.nil?
        @logger = Log4r::Logger.new(self.class.name)
        @logger.trace = true
        @logger.outputters = ['stdout']
        @logger.add 'logfile' if Log4r::Outputter['logfile']
      end
    end
    @logger
  end
end

