require 'ups'
require 'rexml/document'
require 'singleton'
require 'thgexception'

class Configuration
	
	include Singleton

	attr_reader :srcDirectory
	attr_reader :templateFile
	attr_reader :directoryIndexFile

	attr_reader :pluginData

	def initialize
		@homeDir = File.dirname($0)
		@pluginData = Hash.new
		parse_config_file(@homeDir+'/config.xml')
	end
	
	def parse_config_file(filename)
		begin
			@configFile = REXML::Document.new(File.new(filename))
			root = @configFile.root
			
			# initialize attributes
			@templateFile = root.text('/configuration/main/templateFile')
			raise "templateFile entry not found" if @templateFile.nil? 
			@directoryIndexFile = root.text('/configuration/main/directoryIndexFile')
			raise "directoryIndexFile entry not found" if @directoryIndexFile.nil? 
			@srcDirectory = root.text('/configuration/main/srcDir')
			raise "srcDirectory entry not found" if @srcDirectory.nil? 
			raise "srcDirectory does not exist" if !File.exists? @srcDirectory

			# fill plugin data structure
			root.each_element('/configuration/plugins/*') { |element|
				@pluginData[element.name] = element
			}

		rescue
			raise ThaumaturgeException.new("check if the config.xml file exists (path: #{filename})"), 
				"Could not read in the configuration file: #{$!.message}", $!.backtrace
		end
	end

	def loadPlugins
		Dir[@homeDir+'/plugins/*.rb'].each { |file|
			require file
		}
	end

end
