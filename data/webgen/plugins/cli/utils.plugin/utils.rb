require 'facets/more/ansicode'
require 'rbconfig'

Console::ANSICode.define_ansicolor_method( :lred, '1;31' )
Console::ANSICode.define_ansicolor_method( :lblue, '1;34' )

module Cli

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
      if (0..1) === paragraphs.length
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
