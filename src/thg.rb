# add directory of main file thg.rb to lib search path
$:.push File.dirname($0)

require 'thgexception'
require 'ups'
require 'optparse'

# add exception entry for option parsing
ThgException.add_entry :ARG_PARSE_ERROR,
	"%0: %1 %2 %3 %4 %5",
	"look at the online help to correct this error"


def runMain
	# load all the files in src dir and build tree
	tree = UPS::PluginRegistry.instance['fileHandler'].build_tree
	
	# execute tree transformer plugins
	UPS::PluginRegistry.instance['treeTransformer'].execute(tree)
	
	# generate output files
	UPS::PluginRegistry.instance['fileHandler'].write_tree(tree)
end


def runListPlugins
	UPS::PluginRegistry.instance['listRegistry'].list 
end

# everything is catched
begin

	require 'configuration'

	# specify which main method to execute
	main = method(:runMain)
	
	# parse options
	ARGV.options do |opts|
		opts.summary_width = 25
		opts.summary_indent = '  '
		opts.program_name = 'ruby thg.rb'

		opts.banner << "\nThaumaturge is a template based web page generator for offline page generation.\n\n"

		opts.on_tail("--help", "-h", "Display this help screen") { puts opts; exit }
		opts.on("--config-file FILE", "-c", String, "The config.xml which should be used") { |Configuration.instance.configFile| }
		opts.on("--source-dir DIR", "-s", String, "The  directory from where the files are read") { |Configuration.instance.srcDirectory| }
		opts.on("--output-dir DIR", "-o", String, "The directory where the output should go") { |Configuration.instance.outDirectory| }
		opts.on("--list-plugins", "-l", "List all the plugins and information about them") { require 'listplugins'; main = method(:runListPlugins) }
		opts.on("--verbosity LEVEL", "-v", Integer, "The verbosity level (0, 1, or 2)") { |Configuration.instance.verbosityLevel| }

		begin
			opts.parse!
		rescue RuntimeError => e
			raise ThgException.new(ThgException::ARG_PARSE_ERROR, e.reason, e.args[0])
		end
	end
	
	# parse the configuration file
	Configuration.instance.parse_config_file

	# load the plugins
	Configuration.instance.load_plugins

	# run the selected routine
	main.call

rescue ThgException => e
	print "An error occured:\n\t #{e.message}\n\n"
	print "Possible solution:\n\t #{e.solution}\n\n"
	print "Stack trace: #{e.backtrace.join("\n")}\n" if Configuration.instance.verbosityLevel >= 2
end


