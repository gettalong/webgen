require 'facets/ansicode'
require 'rbconfig'

Console::ANSICode.define_ansicolor_method(:lred, '1;31')
Console::ANSICode.define_ansicolor_method(:lblue, '1;34')

module Webgen::CLI

  # Provides methods for other CLI classes for formatting text in a consistent manner.
  class Utils

    USE_ANSI_COLORS = !Config::CONFIG['arch'].include?('mswin32')
    DEFAULT_WIDTH = ((size = %x{stty size 2>/dev/null}).length > 0 ? x.split.last.to_i : 72) rescue 72

    # Used for dynamically formatting the text (setting color, bold face, ...).
    def self.method_missing(id, text = nil)
      if USE_ANSI_COLORS && Console::ANSICode.respond_to?(id)
        Console::ANSICode.send(id, text.to_s)
      else
        text.to_s
      end
    end

    # Return an array of lines which represents the text in +content+ formatted sothat no line is
    # longer than +width+ characters. The +indent+ parameter specifies the amount of spaces
    # prepended to each line. If +first_line_indented+ is +true+, then the first line is indented.
    def self.format(content, indent = 0, first_line_indented = false, width = DEFAULT_WIDTH)
      content = (content || '').dup
      length = width - indent

      paragraphs = content.split(/\n\n/)
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
          lines << (lines.empty? && !first_line_indented ? '' : ' '*indent) + str.gsub(/\n/, ' ')
          content.slice!(0, len)
        end
        lines << (lines.empty? && !first_line_indented ? '' : ' '*indent) + content.gsub(/\n/, ' ') unless content.strip.empty?
        lines
      else
        ((format(paragraphs.shift, indent, first_line_indented, width) << '') +
         paragraphs.collect {|p| format(p, indent, true, width) << '' }).flatten[0..-2]
      end
    end

    # Return a headline with the given +text+ and amount of +indent+.
    def self.headline(text, indent = 2)
      ' '*indent + "#{bold(text)}"
    end

    # Return a section header with the given +text+ formatted in the given +color+ and indented
    # according to +indent+. The whole text is also left justified to the column specified with
    # +ljustlength+.
    def self.section(text, ljustlength = 0, indent = 4, color = :green)
      ' '*indent + "#{send(color, text)}".ljust(ljustlength - indent + send(color).length)
    end

    # Creates a listing of the key-value pairs of +hash+ under a section called +name+.
    def self.hash_output(name, hash)
      ljust = 20
      puts section('Name', ljust) + "#{lred(name)}"

      hash.sort_by {|k,v| k.to_s }.each do |name, value|
        next unless value.respond_to?(:to_str)
        desc = format(value.to_str, ljust)
        puts section(name.to_s.capitalize, ljust) + desc.shift
        desc.each {|line| puts line}
      end
      puts
    end

  end

end
