require 'ups/ups'
require 'ups/listener'
require 'log4r'

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
    attr_accessor :ignoredFiles

	def initialize
		@extensions = Hash.new

		add_msg_name( :DIR_NODE_CREATED )
		add_msg_name( :FILE_NODE_CREATED )
		add_msg_name( :AFTER_DIR_READ )
	end


    def init
        @ignoredFiles = UPS::Registry['Configuration'].get_config_value( NAME, 'ignoredFiles' ) || ['.svn', 'CVS']
    end


	def build_tree
		@dirProcessor = Object.new

		root = build_entry( UPS::Registry['Configuration'].srcDirectory, nil )
		root['title'] = '/'
		root['dest'] = UPS::Registry['Configuration'].outDirectory + File::SEPARATOR
		root['src'] = UPS::Registry['Configuration'].srcDirectory + File::SEPARATOR
		root
	end


	def write_tree( node )
        self.logger.info { "Writing #{node.recursive_value('dest')}" }

		node['processor'].write_node( node )

		node.each do |child|
			write_tree child
		end
	end


    def file_modified?( node )
        src = node.recursive_value 'src'
        dest = node.recursive_value 'dest'
        if File.exists?( dest ) && ( File.mtime( src ) < File.mtime( dest ) )
            self.logger.info { "File is up to date: <#{dest}>" }
            return false
        else
            return true
        end
    end


	#######
	private
	#######

	def build_entry( path, parent )
		self.logger.info { "Processing #{path}" }

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

                entries = Dir[path + File::SEPARATOR + '{.*,*}'].delete_if do |name|
                    name =~ /\/.{1,2}$/ || @ignoredFiles.include?( File.basename( name ) )
                end

                entries.sort! do |a, b|
                     if File.file?( a ) && File.directory?( b )
                         -1
                     elsif ( File.file?( a ) && File.file?( b ) ) || ( File.directory?( a ) && File.directory?( b ) )
                         a <=> b
                     else
                         1
                     end
                end

                entries.each do |filename|
                    child = build_entry( filename, node )
                    node.add_child child unless child.nil?
                end

                dispatch_msg( :AFTER_DIR_READ, node )
            end
        end

        self.logger.warn { "No plugin for path #{path} -> ignored" } if node.nil?
		return node
	end

end


UPS::Registry.register_plugin FileHandler

