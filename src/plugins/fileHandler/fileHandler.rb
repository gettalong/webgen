require 'ups/ups'
require 'ups/listener'
require 'configuration'
require 'thgexception'
require 'node'


class FileHandler < UPS::Plugin

	include Listener

    NAME = "File Handler"
    SHORT_DESC = "Super plugin for handling files"
    DESCRIPTION = <<-EOF.gsub( /^\s+/, '' ).gsub( /\n/, ' ' )
      Provides interface on file level. The FileHandler goes through the source
      directory, reads in all files for which approriate plugins exist and
      builds the tree. When all approriate transformations on the tree have
      been performed the FileHandler is used to write the output files.
    EOF

	attr_accessor :extensions

	def initialize
		@extensions = Hash.new

		#TODO config = Configuration.instance.pluginData['fileHandler']
		#TODO raise ThgException.new(ThgException::CFG_ENTRY_NOT_FOUND, 'fileHandler') if config.nil?

		add_msg_name( :DIR_NODE_CREATED )
		add_msg_name( :FILE_NODE_CREATED )
		add_msg_name( :AFTER_DIR_READ )
	end


	def build_tree
		@dirProcessor = Object.new

		root = build_entry( UPS::Registry['Configuration'].srcDirectory, nil )
		root['dest'] = ""
		root['title'] = '/'
		root['src'] = UPS::Registry['Configuration'].srcDirectory + File::SEPARATOR
		root
	end


	def write_tree( node )
		name = File.join( UPS::Registry['Configuration'].outDirectory, node.recursive_value( 'dest' ) )
        #TODO Configuration.instance.log(Configuration::NORMAL, "Writing #{name}")

		node['processor'].write_node( node, name )

		node.each do |child|
			write_tree child
		end
	end

	#######
	private
	#######

	def build_entry( path, parent )
		#TODO Configuration.instance.log(Configuration::NORMAL, "Processing #{srcName}")

		if FileTest.file? path
			extension = path[/\..*$/][1..-1]

			if @extensions.has_key? extension
				node = @extensions[extension].create_node( path, parent )
				node['processor'] = @extensions[extension]
				dispatch_msg( :FILE_NODE_CREATED, node )
			end
		elsif FileTest.directory? path
			if @extensions.has_key? :dir
                node = @extensions[:dir].create_node( path, parent )
                node['processor'] = @extensions[:dir]

                dispatch_msg( :DIR_NODE_CREATED, node )

                Dir[File.join( path, '*' )].each do |filename|
                    child = build_entry( filename, node )
                    node.add_child child unless child.nil?
                end

                dispatch_msg( :AFTER_DIR_READ, node )
            end
        end

        if node.nil?
            #TODO Configuration.instance.warning("no plugin for path #{path} -> ignored")
        end

		return node
	end

end


UPS::Registry.register_plugin FileHandler

