require 'ups'
require 'rexml/document'
require 'singleton'
require 'thgexception'

class Configuration
	
	include Singleton

	attr_reader :srcDirectory
	attr_reader :templateFile
	attr_reader :directoryIndexFile
	attr_accessor :verbosityLevel
	attr_reader :pluginData

	def initialize
		@homeDir = File.dirname($0)
		@pluginData = Hash.new
	end
	
	def parse_config_file(filename)
		if !File.exists?(filename)
			raise ThgException.new(ThgException::CFG_FILE_NOT_FOUND, filename)
		end

		@configFile = REXML::Document.new(File.new(filename))
		root = @configFile.root
			
		# initialize attributes
		@templateFile = root.text('/configuration/main/templateFile')
		raise ThgException.new(ThgException::CFG_ENTRY_NOT_FOUND, 'templateFile') if @templateFile.nil?

		@directoryIndexFile = root.text('/configuration/main/directoryIndexFile')
		raise ThgException.new(ThgException::CFG_ENTRY_NOT_FOUND, 'directoryIndexFile') if @directoryIndexFile.nil?

		@srcDirectory = root.text('/configuration/main/srcDir')
		raise ThgException.new(ThgException::CFG_ENTRY_NOT_FOUND, 'srcDirectory') if @srcDirectory.nil?
		raise "srcDirectory does not exist" if !File.exists? @srcDirectory

		@verbosityLevel ||= root.text('/configuration/main/verbosityLevel').to_i
		raise ThgException.new(ThgException::CFG_ENTRY_NOT_FOUND, 'verbosityLevel') if @verbosityLevel.nil?

		# fill plugin data structure
		root.each_element('/configuration/plugins/*') { |element|
			@pluginData[element.name] = element
		}
	end

	def loadPlugins
		Dir[@homeDir+'/plugins/*.rb'].each { |file|
			require file
		}
	end

	def log(level, str)
		print str << "\n" if @verbosityLevel >= level
	end

end
