require 'ups/ups'
require 'yaml'
require 'log4r'
require 'log4r/yamlconfigurator'

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
    - name      : plugin
      level     : DEBUG
      additive  : 'false'
      trace     : 'false'
      outputters:
        - logfile
        - stdout

    - name: log4r
      level: DEBUG
      outputters:
        - logfile

  outputters:
    - type     : StdoutOutputter
      name     : stdout
      level    : WARN
      formatter:
        type        : PatternFormatter
        date_pattern: '%Y-%m-%d %H:%M:%S'
        pattern     : '%d %l %c: %m'

    - type        : FileOutputter
      name        : logfile
      level       : DEBUG
      trunc       : 'false'
      filename    : 'thg.log'
      formatter   :
        type        : PatternFormatter
        date_pattern: '%Y-%m-%d %H:%M:%S'
        pattern     : '%d %l %c: %m'

EOF
cfg = Log4r::YamlConfigurator
cfg.load_yaml_string LoggerConfiguration

class ThgConfigurationPlugin < UPS::Plugin

    NAME = "Configuration"
    SHORT_DESC = "Responsible for loading the configuration data"

	attr_accessor :srcDirectory
	attr_accessor :outDirectory
	attr_accessor :verbosityLevel
	attr_accessor :configFile

	attr_reader :pluginData


    def initialize
        @homeDir = File.dirname( $0 )
        @configFile = 'config.yaml'
        @pluginData = Hash.new
    end


	def parse_config_file
        if File.exists? @configFile
            @pluginData = YAML::load( File.new( @configFile ) )
        end

        @srcDirectory ||= get_config_value( 'Configuration', 'srcDirectory' ) || 'src'
        @outDirectory ||= get_config_value( 'Configuration', 'outDirectory' ) || 'output'
        @verbosityLevel ||= get_config_value( 'Configuration', 'verbosityLevel' ) || 3
        Log4r::Outputter['stdout'].level = @verbosityLevel
	end


    def get_config_value( plugin, key )
        return unless @pluginData.has_key? plugin
        @pluginData[plugin][key]
    end

end

UPS::Registry.register_plugin( ThgConfigurationPlugin )
