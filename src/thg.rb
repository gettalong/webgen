# add directory of main file thg.rb to lib search path
$:.push File.dirname($0)

require 'thgexception'

# add exception entry for option parsing
ThgException.add_entry :ARG_PARSE_ERROR,
	"%0: %1 %2 %3 %4 %5",
	"look at the online help to correct this error"

# everything is catched
begin

	require 'ups'
	require 'optparse'
	
	require 'configuration'
	require 'tree'

	class ConvertMain < UPS::StandardPlugin

		def initialize
			super('main', 'thaumaturge')
		end

		def describe
			"Executes the main branch of the progam. The main branch does the actual work, " <<
				"i.e. it reads in all the files, transforms them and then produces the output "<<
				"files."
		end

		def run(*arg)
			# load all the files in src dir and build tree
			tree = UPS::PluginRegistry.instance['fileHandler'].build_tree
			Configuration.instance.log(2, "Tree: #{tree.inspect}")
			
			# execute tree transformer plugins
			UPS::PluginRegistry.instance['treeTransformer'].execute(tree)
			
			# generate output files
			UPS::PluginRegistry.instance['fileHandler'].write_tree(tree)
		end

	end

	class THGListPlugin < UPS::StandardPlugin
		
		def initialize
			super('listRegistry', 'thgPluginList')
		end

		def describe
			"Pretty prints the controller and plugin describtions"
		end

		def after_register
			UPS::PluginRegistry.instance['listRegistry'].set_plugin('thgPluginList')
		end

		def processController(order, controller)
			if order == UPS::ListController::BEFORE
				print "Controller group '#{controller.id}':\n"
			else
				print "\n"
			end
		end

		def processPlugin(plugin)
			if plugin.respond_to? :describe
				print "  Plugin '#{plugin.id}:'\n"
				width = 0;
				print "    "+plugin.describe.split(' ').collect {|s|
					width += s.length
					ret = ""
					if width > 60
						ret << "\n    "
						width = 0 
					end
					ret << s << ' '
				}.join('') + "\n\n"
			end
		end

	end

	class ListPluginMain < UPS::StandardPlugin
		
		def initialize
			super('main', 'listPlugins')
		end

		def describe
			"Prints out a description of all plugins which have a describe method"
		end

		def run(*arg)
			UPS::PluginRegistry.instance['listRegistry'].list		
		end

	end

	UPS::PluginRegistry.instance.register_plugin(ConvertMain.new)
	UPS::PluginRegistry.instance.register_plugin(ListPluginMain.new)
	UPS::PluginRegistry.instance.register_plugin(THGListPlugin.new)


	# specify which main plugin to execute
	main = 'thaumaturge'
	
	# parse options
	ARGV.options do |opts|
		opts.summary_width = 25
		opts.summary_indent = '  '
		opts.program_name = 'ruby thg.rb'

		opts.banner << "\nThaumaturge is a template based web page generator for offline page generation.\n\n"

		opts.on_tail("--help", "-h", "Display this help screen") { puts opts; exit }
		opts.on("--config-file FILE", "-c", String, "The config.xml which should be used") { |Configuration.instance.configFile| }
		opts.on("--list-plugins", "-l", "List all the plugins and information about them") { main = 'listPlugins' }
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
	

	UPS::PluginRegistry.instance['main'].set_plugin(main)
	UPS::PluginRegistry.instance['main'].run(ARGV)
	

rescue ThgException => e
	print "An error occured:\n\t #{e.message}\n\n"
	print "Possible solution:\n\t #{e.solution}\n\n"
	#print "Stack trace: #{e.backtrace.join("\n")}\n"
end
