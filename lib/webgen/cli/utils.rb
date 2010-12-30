# -*- encoding: utf-8 -*-

require 'rbconfig'

module Webgen

  module CLI

    # Provides methods for other CLI classes for formatting text in a consistent manner.
    class Utils

      USE_ANSI_COLORS = $stdout.tty? && Config::CONFIG['host_os'] !~ /mswin|mingw/
      DEFAULT_WIDTH = if Config::CONFIG['host_os'] =~ /mswin|mingw/
                        72
                      else
                        ((size = %x{stty size 2>/dev/null}).length > 0 && (size = size.split.last.to_i) > 0 ? size : 72) rescue 72
                      end

      module Color

        @@colors = {:bold => [1], :light => [1], :green => [32], :yellow => [33], :red => [31], :reset => [0]}

        @@colors.each do |color, values|
          module_eval("def Color.#{color.to_s}(text = nil);" <<
                      "'\e[#{values.join(';')}m' << (text.nil? ? '' : text + self.reset); end")
        end

      end


      # Used for dynamically formatting the text (setting color, bold face, ...).
      def self.method_missing(id, text = nil)
        if USE_ANSI_COLORS && Color.respond_to?(id)
          Color.send(id, text)
        else
          text.to_s
        end
      end

      # Return an array of lines which represents the text in +content+ formatted so that no line is
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

        hash.sort_by {|k,v| k.to_s }.each do |n, value|
          next unless value.respond_to?(:to_str)
          desc = format(value.to_str, ljust)
          puts section(n.to_s.capitalize, ljust) + desc.shift
          desc.each {|line| puts line}
        end
        puts
      end

      # Tries to match +name+ to a unique bundle name of the WebsiteManager +wm+. If this can not be
      # done, it is checked whether +name+ is actually a valid bundle URL and if so, the URL source is
      # added to the bundles of +wm+.
      #
      # Returns the correct bundle name or raises an error.
      def self.match_bundle_name(wm, name)
        matches = wm.bundles.keys.select {|k| k =~ /#{Regexp.escape(name)}/}
        if matches.size > 1
          raise ArgumentError.new("#{name} matches more than one bundle: #{matches.join(", ")}")
        elsif matches.size == 0
          begin
            source = Webgen::Source::TarArchive.new(name)
            wm.add_source(source, 'custom-URL-source')
            name = 'custom-URL-source'
          rescue
            raise ArgumentError.new("#{name} is neither a valid bundle name nor a valid URL")
          end
        else
          name = matches.first
        end
        name
      end

    end

  end

end
