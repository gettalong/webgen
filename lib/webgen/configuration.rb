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

      @srcDirectory ||= add_config_param( NAME, 'srcDirectory', 'src', 'The directory from which the source files are read.' )
      @outDirectory ||= add_config_param( NAME, 'outDirectory', 'output', 'The directory to which the output files are written.' )
      @verbosityLevel ||= add_config_param( NAME, 'verbosityLevel', 3, 'The level of verbosity for the output of messages on the standard output.' )
      @lang ||= add_config_param( NAME, 'lang', 'en', 'The default language.' )
      Log4r::Outputter['stdout'].level = @verbosityLevel
    end


    def load_file_outputter
      Log4r::YamlConfigurator.load_yaml_string FileOutputterConfiguration
    end


    def add_config_param( pluginName, paramName, defaultValue, description = nil )
      value = @pluginData[pluginName][paramName] if @pluginData.has_key?( pluginName ) && @pluginData[pluginName].has_key?( paramName )
      value ||= defaultValue

      paramData = OpenStruct.new( :name => paramName, :value => value, :defaultValue => defaultValue, :description => description.to_s )
      @configParams[pluginName] ||= Hash.new
      @configParams[pluginName][paramName] = paramData

      return value
    end

  end

  UPS::Registry.register_plugin( WebgenConfigurationPlugin )


  class Plugin < UPS::Plugin

    def init
      @config = {}
      if self.class.const_defined? :CONFIG_PARAMS
        self.class::CONFIG_PARAMS.each do |param|
          value = UPS::Registry['Configuration'].add_config_param( self.class::NAME, param[:name], param[:defaultValue], param[:description] )
          @config[param[:name]] = value
        end
      end
      self.class.ancestors[1..-1].each do |klass|
        if klass.const_defined? :CONFIG_PARAMS
          klass::CONFIG_PARAMS.each do |param|
            @config[param[:name]] = UPS::Registry['Configuration'].configParams[klass::NAME][param[:name]].value
          end
        end
      end
    end


    def self.no_init_inheritance
      module_eval "@@PLUGIN_INIT = true"
    end


    def self.method_added( id )
      return if id != :init || self.class_variables.include?( '@@PLUGIN_INIT' )
      aliasName = "init_" + self.object_id.to_s
      unless method_defined?( aliasName )
        module_eval "alias_method(:#{aliasName}, :init)\n def init() super; #{aliasName}; end"
      end
    end


    def get_config_param( name )
      if !@config.nil? && @config.has_key?( name )
        return @config[name]
      else
        self.logger.error { "Referencing invalid configuration value '#{name}' in class #{self.class.name}" }
        return nil
      end
    end

  end

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
    if !defined? @logger
      @logger = Log4r::Logger[self.class.name]
      if @logger.nil?
        @logger = Log4r::Logger.new( self.class.name )
        @logger.trace = true
        @logger.outputters = ['stdout']
        @logger.add 'logfile' if Log4r::Outputter['logfile']
      end
    end
    @logger
  end
end

