require 'term/ansicolor'
require 'ups'
require 'rexml/document'
require 'singleton'
require 'thgexception'

class AnsiColor
	class << self
		include Term::ANSIColor
	end
end

class Configuration

	NORMAL  = 1
	WARNING = 2
	DEBUG   = 3

	ThgException.add_entry :CFG_ENTRY_NOT_FOUND,
		"%0 entry in configuration file %1 not found", 
		"add entry %0 to the configuration file"

	ThgException.add_entry :CFG_FILE_NOT_FOUND,
		"configuration file not found",
		"create the configuration file (current search path: %0)"

	include Singleton

	attr_accessor :srcDirectory
	attr_accessor :outDirectory	
	attr_accessor :verbosityLevel
	attr_accessor :configFile

	attr_reader :pluginData

	def initialize
		@homeDir = File.dirname($0)
		@configFile = File.join(@homeDir, 'config.xml')
		@pluginData = Hash.new
	end
	
	def parse_config_file
		raise ThgException.new(ThgException::CFG_FILE_NOT_FOUND, @configFile) if !File.exists?(@configFile)

		root = REXML::Document.new(File.new(@configFile)).root
			
		# initialize attributes
		read_config_value(root, :@srcDirectory, '/configuration/main/srcDir')
		read_config_value(root, :@outDirectory, '/configuration/main/outDir')
		read_config_value(root, :@verbosityLevel, '/configuration/main/verbosityLevel', Integer)

		# fill plugin data structure
		root.each_element('/configuration/plugins/*') { |element|
			@pluginData[element.name] = element
		}
	end

	def load_plugins
		UPS::PluginRegistry.instance.load_plugins(@homeDir+'/plugins')
	end

	def log(level, str)
		if @verbosityLevel >= level
			print Time.now.strftime('%Y%m%d%H%M%S') << ' >> ' 
			case level
			when 2
				print AnsiColor.green, 'WARNING: '
			when 3
				print AnsiColor.red, 'DEBUG: '
			end
			print str, AnsiColor.reset, "\n" 
		end
	end

	def warning(str)
		log(WARNING, str)
	end
	
	def debug(str)
		log(DEBUG, str)
	end

	#######
	private
	#######

	def read_config_value(root, symbol, path, type = String)
		eval(symbol.id2name << " ||= root.text(path)")
		raise ThgException.new(ThgException::CFG_ENTRY_NOT_FOUND, path, @configFile) if eval(symbol.id2name << ".nil?")
		eval(symbol.id2name << " = " << type.to_s << "(" << symbol.id2name << ")")
	end
	
end
