require 'facets/more/ansicode'
require 'rbconfig'

Console::ANSICode.define_ansicolor_method( :lred, '1;31' )

module Cli

  class Utils

    USE_ANSI_COLORS = $stdout.isatty && !Config::CONFIG['arch'].include?( 'mswin32' )

    def self.method_missing( id, text = nil )
      if USE_ANSI_COLORS && Console::ANSICode.respond_to?( id )
        Console::ANSICode.send( id, text.to_s )
      else
        text.to_s
      end
    end

    def self.format( content, indent = 0, width = 100 )
      content ||= ''
      return [content] if content.length + indent <= width
      lines = []
      while content.length + indent > width
        index = content[0..(width-indent-1)].rindex(' ')
        lines << (lines.empty? ? '' : ' '*indent) + content[0..index]
        content = content[index+1..-1]
      end
      lines << ' '*indent + content unless content.strip.empty?
      lines
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
