require 'facets/more/ansicode'
require 'rbconfig'

Console::ANSICode.define_ansicolor_method( :lred, '1;31' )
Console::ANSICode.define_ansicolor_method( :lblue, '1;34' )

module Cli

  class Utils

    USE_ANSI_COLORS = !Config::CONFIG['arch'].include?( 'mswin32' )

    def self.method_missing( id, text = nil )
      if USE_ANSI_COLORS && Console::ANSICode.respond_to?( id )
        Console::ANSICode.send( id, text.to_s )
      else
        text.to_s
      end
    end

    def self.format( content, indent = 0, width = 72, hanging_indent = true )
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
          lines << (lines.empty? && hanging_indent ? '' : ' '*indent) + str.gsub( /\n/, ' ' )
          content.slice!(0, len)
        end
        lines << (lines.empty? && hanging_indent ? '' : ' '*indent) + content.gsub( /\n/, ' ' ) unless content.strip.empty?
        lines
      else
        ((format( paragraphs.shift, indent, width, hanging_indent ) << '') +
         paragraphs.collect {|p| format( p, indent, width, false ) << '' }).flatten[0..-2]
      end
    end

    def self.headline( text, indent = 2 )
      ' '*indent + "#{bold( text )}"
    end

    def self.section( text, ljustlength = 0, indent = 4, color = :green )
      ' '*indent + "#{send( color, text )}".ljust( ljustlength - indent + send( color ).length )
    end

    def self.dirinfo_output( opts, name, dirinfo )
      ljust = 15 + opts.summary_indent.length
      opts.separator section( 'Name', ljust, opts.summary_indent.length + 2 ) + "#{lred( name )}"

      dirinfo.infos.sort.each do |name, value|
        desc = format( value, ljust )
        opts.separator section( name.capitalize, ljust, opts.summary_indent.length + 2 ) + desc.shift
        desc.each {|line| opts.separator line}
      end
      opts.separator ''
    end

  end

end
