require 'yaml'
require 'log4r'
require 'log4r/yamlconfigurator'
require 'util/ups'


module Thaumaturge

    VERSION = "0.1.0"
    NAME = "Thaumaturge"
    DESCRIPTION = "Thaumaturge is a template based web page generator."


    class ThgConfigurationPlugin < UPS::Plugin

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
            @configParams[pluginName] ||= Array.new
            @configParams[pluginName].push [key, value, defaultValue]
            value
        end

    end

    UPS::Registry.register_plugin( ThgConfigurationPlugin )

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
      outputters:
        - stdout

  outputters:
    - type     : StdoutOutputter
      name     : stdout
      level    : WARN
      formatter:
        type        : PatternFormatter
        date_pattern: '%Y-%m-%d %H:%M:%S'
        pattern     : '%d %-5l %-20c> %m'

EOF

FileOutputterConfiguration = <<EOF
log4r_config:
  loggers: {}

  outputters:
    - type        : FileOutputter
      name        : logfile
      level       : DEBUG
      trunc       : 'false'
      filename    : 'thg.log'
      formatter   :
        type        : PatternFormatter
        date_pattern: '%Y-%m-%d %H:%M:%S'
        pattern     : '%d %5l %-20c> %m'

EOF
Log4r::YamlConfigurator.load_yaml_string LoggerConfiguration

class Object
    def logger
        if @logger.nil?
            @logger = Log4r::Logger.new(self.class.name)
            @logger.outputters = ['stdout']
            @logger.add 'logfile' if Log4r::Outputter['logfile']
        end
        @logger
    end
end

