require 'facets/more/ansicode'
require 'rbconfig'

Console::ANSICode.define_ansicolor_method( :lred, '1;31' )
Console::ANSICode.define_ansicolor_method( :lblue, '1;34' )

module Cli

  # = CLI commands
  #
  # Each CLI command should be put into this module. A CLI command is a plugin that can be invoked
  # from the webgen command and thus needs to be derived from CmdParse::Command. For detailed
  # information on this class and the whole cmdparse package have a look at
  # http://cmdparse.rubyforge.org!
  #
  # Here is a sample CLI command plugin:
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


  # Provides methods for other CLI plugins for formatting text in a consistent manner.
  class Utils

    USE_ANSI_COLORS = !Config::CONFIG['arch'].include?( 'mswin32' )

    # Used for dynamically formatting the text (setting color, bold face, ...).
    def self.method_missing( id, text = nil )
      if USE_ANSI_COLORS && Console::ANSICode.respond_to?( id )
        Console::ANSICode.send( id, text.to_s )
      else
        text.to_s
      end
    end

    # Returns an array of lines which represents the text in +content+ formatted sothat no line is
    # longer than +width+ characters. The +indent+ parameter specifies the amount of spaces
    # prepended to each line. If +first_line_unindented+ is +true+, then the first line is not
    # indented.
    def self.format( content, indent = 0, width = 72, first_line_unindented = true )
      content ||= ''
      length = width - indent

      paragraphs = content.split( /\n\n/ )
      if paragraphs.length == 1
        pattern = /^(.{0,#{length}})[ \n]/m
        lines = []
        while content.length > length
          if content =~ pattern
            str = $1
            len = $&.length
          else
            str = content[0, length]
            len = length
          end
          lines << (lines.empty? && first_line_unindented ? '' : ' '*indent) + str.gsub( /\n/, ' ' )
          content.slice!(0, len)
        end
        lines << (lines.empty? && first_line_unindented ? '' : ' '*indent) + content.gsub( /\n/, ' ' ) unless content.strip.empty?
        lines
      else
        ((format( paragraphs.shift, indent, width, first_line_unindented ) << '') +
         paragraphs.collect {|p| format( p, indent, width, false ) << '' }).flatten[0..-2]
      end
    end

    # Returns a headline with the given +text+ and amount of +indent+.
    def self.headline( text, indent = 2 )
      ' '*indent + "#{bold( text )}"
    end

    # Returns a section header with the given +text+ formatted in the given +color+ and indented
    # according to +indent+. The whole text is also left justified to the column specified with
    # +ljustlength+.
    def self.section( text, ljustlength = 0, indent = 4, color = :green )
      ' '*indent + "#{send( color, text )}".ljust( ljustlength - indent + send( color ).length )
    end

    # Uses the OptionParser in +opts+ to create a section called +name+ which is filled with data
    # from the +infos+ hash.
    def self.info_output( opts, name, infos )
      ljust = 15 + opts.summary_indent.length
      opts.separator section( 'Name', ljust, opts.summary_indent.length + 2 ) + "#{lred( name )}"

      infos.sort.each do |name, value|
        desc = format( value, ljust )
        opts.separator section( name.capitalize, ljust, opts.summary_indent.length + 2 ) + desc.shift
        desc.each {|line| opts.separator line}
      end
      opts.separator ''
    end

  end

end
