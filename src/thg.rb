# add directory of main file thg.rb to lib search path
$:.push File.dirname($0)

require 'ups'

require 'configuration'
require 'parser'
require 'tree'


class ThaumaturgeException < Exception
	attr_accessor :solution

	def initialize
		@solution = 'None available'
	end
end

class Main < UPS::StandardPlugin

	def initialize
		super('main', 'thaumaturge')
	end

	def after_register
		UPS::PluginRegistry.instance['main'].set_plugin('thaumaturge')
	end

	def run(*arg)
		begin
			# initialise the configuration
			cfg = Configuration.new

			# load the plugins
			cfg.loadPlugins

			# load all the files in src dir and build tree
			parser = Parser.new(cfg.srcDirectory)
			tree = parser.build_tree

			#UPS::PluginRegistry.instance['listRegistry'].list
			
			# execute tree transformer plugins
			UPS::PluginRegistry.instance['treeTransformer'].execute(tree)

			# generate output files
			UPS::PluginRegistry.instance['fileWriter'].execute(tree)

		rescue ThaumaturgeException => e
			print "\nAn error occured: #{e.message}\n"
			print "Possible solution: #{e.solution}\n"
		end
	end

end

UPS::PluginRegistry.instance.register_plugin(Main.new)
UPS::PluginRegistry.instance['main'].run(ARGV)
