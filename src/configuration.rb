require 'ups'
require 'rexml/Document'

class Configuration

	attr_reader :srcDirectory
	attr_reader :outputDirectory

	def initialize
		@homeDir = File.dirname($0)
		parse_config_file(@homeDir+'/config.xml')
	end
	
	def parse_config_file(filename)
		
	end

	def loadPlugins
		Dir[@homeDir+'/plugins/*.rb'].each { |file|
			require file
		}
	end

end
