require 'ups/ups'
require 'yaml'
require 'singleton'
require 'thgexception'
require 'log4r'

# Logger configuration
Log4r::Logger.root.level = Log4r::INFO


class ThgConfigurationPlugin < UPS::Plugin

    NAME = "Configuration"
    SHORT_DESC = "Responsible for loading the configuration data"

	ThgException.add_entry :CFG_ENTRY_NOT_FOUND,
		"%0 entry in configuration file %1 not found",
		"add entry %0 to the configuration file"

	ThgException.add_entry :CFG_FILE_NOT_FOUND,
		"configuration file not found",
		"create the configuration file (current search path: %0)"

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
		raise ThgException.new( :CFG_FILE_NOT_FOUND, @configFile ) unless File.exists? @configFile

		@pluginData = YAML::load( File.new( @configFile ) )

        @srcDirectory ||= @pluginData['Configuration']['srcDirectory']
        @outDirectory ||= @pluginData['Configuration']['outDirectory']
        @verbosityLevel ||= @pluginData['Configuration']['verbosityLevel']

        @pluginData.delete 'Configuration'
	end

    def get_config_value( plugin, key )
        return unless @pluginData.has_key? plugin
        @pluginData[plugin][key]
    end

end

UPS::Registry.register_plugin( ThgConfigurationPlugin )
