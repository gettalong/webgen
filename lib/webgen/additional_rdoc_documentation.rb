module Cli

  # = CLI commands
  #
  # Each CLI command should be put into this module. A CLI command is a plugin that can be invoked
  # from the webgen command and thus needs to be derived from CmdParse::Command. For detailed
  # information on this class and the whole cmdparse package have a look at
  # http://cmdparse.rubyforge.org!
  #
  # = Sample Plugin
  #
  # Here is a sample CLI command plugin:
  #
  # The <tt>plugin.yaml</tt>
  #
  #   Cli/Commands/SampleCommand:
  #     file:
  #       class: SampleCommand
  #
  # It is necessary to put a cli command plugin into the <tt>Cli/Commands</tt> category,
  # otherwise it is not found later!
  #
  # The <tt>plugin.rb</tt> file:
  #
  #   class SampleCommand < CmdParse::Command
  #
  #     def initialize
  #       super( 'sample', false )
  #       self.short_desc = "This sample plugin just outputs its parameters"
  #       self.description = Utils.format( "\nUses the global verbosity level and outputs additional " +
  #         "information when the level is set to 0 or 1!" )
  #       @username = nil
  #     end
  #
  #     def init_plugin
  #       self.options = CmdParse::OptionParserWrapper.new do |opts|
  #         opts.separator "Options:"
  #         opts.on( '-u', '--user USER', String,
  #           'Specify an additional user name to output' ) {|@username|}
  #       end
  #     end
  #
  #     def execute( args )
  #       if args.length == 0
  #         raise OptionParser::MissingArgument.new( 'ARG1 [ARG2 ...]' )
  #       else
  #         puts "Command line arguments:"
  #         args.each {|arg| puts arg}
  #         if (0..1) === commandparser.verbosity
  #           puts "Yeah, some additional information is always cool!"
  #         end
  #         puts "The entered username: #{@username}" if @username
  #       end
  #     end
  #
  #   end
  #
  # If you need to define options for a command, it is best to do this in the #init_plugin method
  # since the plugin manager instance is available there. Also note the use of Utils.format in the
  # initialize method so that the long text gets wrapped correctly! The Utils class provides some
  # other useful methods, too!
  #
  # For information about which attributes are available on the webgen command parser instance have
  # a look at Webgen::CommandParser!
  module Commands end

end


# = Content Processors
#
# This module houses all content processor plugins, ie. plugins that are used to process the content
# of files in WebPage Format. A content processor is invoked with the content of a block and needs
# to return the modified content or should raise an error if something unusual happens.
#
# A content processor plugin needs to define a single method called +process+ which takes three
# arguments:
#
# :+content+:: This is the string which should be processed.
#
# :+context+:: This parameter is a hash which provides a rendering context. It provides at least the
#              following: <tt>:chain</tt> (the node chain) and <tt>:processors</tt> (the list of all
#              useable content processors).
#
# :+options+:: This hash is populated with options specific to the block (see Block#options)
#
# The first node in the node chain is the reference node which is the source of the content (the
# block) which should be processed.
#
# = Sample Plugin
#
# Here is a sample content processor plugin:
#
# The <tt>plugin.yaml</tt> file:
#
#   ContentProcessor/SamplePlugin:
#     processes: sample
#
# It is necessary to put a content processor plugin into the <tt>ContentProcessor</tt> category,
# otherwise it is not found later! Also make sure that you add the +processes+ information that
# specifies which key is used to uniquely identify this content processor plugin.
#
# The <tt>plugin.rb</tt> file:
#
#   module ContentProcessor
#
#   class SamplePlugin
#
#     def process( content, context, options )
#       chain = context[:chain]
#       ref_node = chain.first
#       node = chain.last
#       if !node['replaceKey'].to_s.empty?
#         content = content.gsub( /#{node['replaceKey']}:([\w\/.]+)/ ) do |match|
#           dest_node = ref_node.resolve_node( $1, node['lang'] )
#           if dest_node
#             dest_node.link_from( node )
#           else
#             match
#           end
#         end
#       end
#     rescue Exception => e
#       raise "Error while replacing special key: #{e.message}"
#     end
#
#   end
#
#   end
#
# This sample plugin replaces special keys with links to pages. For example, if the meta information
# +replaceKey+ is set to +testit+, the following text
#   this is a test for a testit:index.page link!
# with the following
#   this is a test for a <a href='index.html'>Index</a> link!
#
# Also note how the reference node and the current node are used sothat links are correctly
# resolved!
module ContentProcessor
end
