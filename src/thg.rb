require 'thgexception'
require 'ups/ups'
require 'optparse'

def runMain
	# load all the files in src dir and build tree
	tree = UPS::Registry['File Handler'].build_tree

	# execute tree transformer plugins
	UPS::Registry['Tree Transformer'].execute( tree )

	# generate output files
	UPS::Registry['File Handler'].write_tree( tree )
end


def runListPlugins
    print "List of loaded plugins:\n"
	UPS::Registry[ThgListPlugin::NAME].list_plugins
end

# everything is catched
begin

	require 'configuration'

    config = UPS::Registry['Configuration']

	# specify which main method to execute
	main = method( :runMain )

	# parse options
	ARGV.options do |opts|
		opts.summary_width = 25
		opts.summary_indent = '  '
		opts.program_name = 'ruby thg.rb'

		opts.banner << "\nThaumaturge is a template based web page generator for offline page generation.\n\n"

		opts.on_tail( "--help", "-h", "Display this help screen" ) { puts opts; exit }
		opts.on( "--config-file FILE", "-c", String, "The configuration file which should be used" ) { |config.configFile| }
		opts.on( "--source-dir DIR", "-s", String, "The  directory from where the files are read" ) { |config.srcDirectory| }
		opts.on( "--output-dir DIR", "-o", String, "The directory where the output should go" ) { |config.outDirectory| }
		opts.on( "--list-plugins", "-l", "List all the plugins and information about them" ) { require 'listplugins'; main = method(:runListPlugins) }
		opts.on( "--verbosity LEVEL", "-v", Integer, "The verbosity level" ) { |config.verbosityLevel| }

		begin
			opts.parse!
		rescue RuntimeError => e
            print "Error:\n" << e.reason << ": " << e.args.join(", ") << "\n\n"
            puts opts
            exit
		end
	end

	# parse the configuration file
	config.parse_config_file

    Log4r::Logger['plugin'].info "Starting Thaumaturge..."

	UPS::Registry.load_plugins( File.dirname( __FILE__) + '/plugins', File.dirname( __FILE__) + "/" )
	main.call

    Log4r::Logger['plugin'].info "Thaumaturge finished"

rescue ThgException => e
	print "An error occured:\n\t #{e.message}\n\n"
	print "Possible solution:\n\t #{e.solution}\n\n"
	print "Stack trace: #{e.backtrace.join("\n")}\n" if UPS::Registry['Configuration'].verbosityLevel >= 2
end


