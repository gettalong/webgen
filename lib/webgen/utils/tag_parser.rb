# -*- encoding: utf-8 -*-

require 'yaml'
require 'strscan'
require 'webgen/error'

module Webgen
  module Utils

    # This class is used to parse a string for webgen tags and replace them with dynamically
    # generated content. See #replace_tags for more information.
    class TagParser

      # Raised by the Webgen::Utils::TagParser class.
      class Error < Webgen::Error

        attr_accessor :line
        attr_accessor :column

      end


      # Create a new TagParser object, optionally providing a tag prefix.
      def initialize(prefix = nil)
        @start_re = /(\\*)\{#{prefix}(\w+)(::?)/
        @end_re = /(\\*)\{#{prefix}(\w+)\}/
      end

      BRACKETS_RE = /([{}])/ # :nodoc:
      ProcessingStruct = Struct.new(:state, :tag, :simple_tag, :backslashes, :brackets, :start_pos, :end_pos,
                                    :params_start_pos, :params_end_pos, :body_end_pos) # :nodoc:

      # Return the +content+ with all webgen tags replaced.
      #
      # When a webgen tag is encountered by the parser, the method yields all found information and
      # substitutes the returned string for the tag.
      def replace_tags(content) #:yields: tag_name, params, body
        scanner = StringScanner.new(content)
        data = ProcessingStruct.new(:before_tag)
        while true
          case data.state
          when :before_tag
            if scanner.skip_until(@start_re)
              data.state = :in_start_tag
              data.backslashes = scanner[1].length
              data.brackets = 1
              data.tag = scanner[2]
              data.simple_tag = (scanner[3] == ':')
              data.params_start_pos = scanner.pos
              data.start_pos = scanner.pos - scanner.matched.length
            else
              data.state = :done
            end

          when :in_start_tag
            data.brackets += (scanner[1] == '{' ? 1 : -1) while data.brackets != 0 && scanner.skip_until(BRACKETS_RE)
            if data.brackets != 0
              raise Error.new("Unbalanced curly brackets found for tag '#{data.tag}'")
            else
              data.params_end_pos = data.body_end_pos = data.end_pos = scanner.pos - 1
              data.state = (data.simple_tag ? :process : :in_body)
            end

          when :process
            begin
              enc = scanner.string.encoding
              scanner.string.force_encoding('ASCII-8BIT')
              if data.backslashes % 2 == 0
                params = parse_params(scanner.string[data.params_start_pos...data.params_end_pos].force_encoding(enc),
                                      data.tag)
                result = yield(data.tag, params,
                               scanner.string[(data.params_end_pos+1)...data.body_end_pos].to_s.force_encoding(enc))
                result = result.to_s.force_encoding('ASCII-8BIT')
                scanner.string[data.start_pos..data.end_pos] = "\\" * (data.backslashes / 2) + result
                scanner.pos = data.start_pos + result.length
              else
                scanner.string[data.start_pos, 1 + data.backslashes / 2] = ''
                scanner.pos -= 1 + data.backslashes / 2
              end
            ensure
              scanner.string.force_encoding(enc)
            end
            data.state = :before_tag

          when :in_body
            while (result = scanner.skip_until(@end_re))
              next unless scanner[2] == data.tag
              if scanner[1].length % 2 == 1
                scanner.string[(scanner.pos - scanner.matched.length), 1 + scanner[1].length / 2] = ''
                scanner.pos -= 1 + scanner[1].length / 2
              else
                break
              end
            end
            if result
              data.state = :process
              data.end_pos = scanner.pos - 1
              data.body_end_pos = scanner.pos - scanner.matched.length + scanner[1].length / 2
            else
              raise Error.new("Invalid body part - no end tag found for '#{data.tag}'")
            end

          when :done
            break
          end
        end
        scanner.string
      rescue Error => e
        e.line = scanner.string[0...data.start_pos].scan("\n").size + 1
        e.column = data.start_pos - (scanner.string.rindex("\n", data.start_pos) || -1)
        raise
      end

      # Parse the parameter string and return the result.
      def parse_params(param_string, tag)
        YAML::load("--- #{param_string}")
      rescue ArgumentError, SyntaxError, YAML::SyntaxError => e
        raise Error.new("Could not parse parameter string '#{param_string}' for tag '#{tag}': #{e.message}")
      end

    end

  end
end
