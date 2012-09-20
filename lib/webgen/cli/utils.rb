# -*- encoding: utf-8 -*-

require 'rbconfig'

module Webgen

  module CLI

    # Provides methods for CLI classes for formatting text in a consistent manner.
    module Utils

      class << self; attr_accessor :use_colors; end
      @use_colors = $stdout.tty? && RbConfig::CONFIG['host_os'] !~ /mswin|mingw/

      DEFAULT_WIDTH = 80

      module Color # :nodoc:

        @@colors = {:bold => [1], :light => [1], :green => [32], :yellow => [33], :red => [31], :blue => [34], :reset => [0]}

        @@colors.each do |color, values|
          module_eval("def Color.#{color.to_s}(text = nil);" <<
                      "'\e[#{values.join(';')}m' << (text.nil? ? '' : text + self.reset); end")
        end

      end


      # Used for dynamically formatting the text (setting color, bold face, ...).
      #
      # The +id+ (method name) can be one of the following: bold, light, green, yellow, red, blue,
      # reset.
      def self.method_missing(id, text = nil)
        if self.use_colors && Color.respond_to?(id)
          Color.send(id, text)
        else
          text.to_s
        end
      end

      # Format the command description.
      #
      # Returns an array of Strings.
      #
      # See Utils.format for more information.
      def self.format_command_desc(desc)
        format(desc, 76)
      end

      # Format the option description.
      #
      # Returns an array of Strings.
      #
      # See Utils.format for more information.
      def self.format_option_desc(desc)
        format(desc, 48)
      end

      # Return an array of lines which represents the text in +content+ formatted so that no line is
      # longer than +width+ characters.
      #
      # The +indent+ parameter specifies the amount of spaces prepended to each line. If
      # +first_line_indented+ is +true+, then the first line is indented.
      def self.format(content, width = DEFAULT_WIDTH, indent = 0, first_line_indented = false)
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
          ((format(paragraphs.shift, width, indent, first_line_indented) << '') +
           paragraphs.collect {|p| format(p, width, indent, true) << '' }).flatten[0..-2]
        end
      end

    end

  end

end
