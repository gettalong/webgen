require 'ups/ups'
require 'yaml'
require 'log4r'

# Logger configuration
#TODO use verbosityLevel to set logger level
Log4r::Logger.root.level = Log4r::INFO


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
        @verbosityLevel ||= get_config_value( 'Configuration', 'verbosityLevel' ) || 0
	end


    def get_config_value( plugin, key )
        return unless @pluginData.has_key? plugin
        @pluginData[plugin][key]
    end

end

UPS::Registry.register_plugin( ThgConfigurationPlugin )
