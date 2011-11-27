# -*- encoding: utf-8 -*-

require 'yaml'
require 'webgen/error'

module Webgen

  # A Page object wraps a meta information hash and an array of Block objects. It is normally
  # generated from a file or string in Webgen Page Format using the provided class methods.
  class Page

    # A single block within a Page object. The content of the block can be rendered using the #render method.
    class Block

      # The name of the block.
      attr_reader :name

      # The content of the block.
      attr_reader :content

      # Create a new block with the given +name+ and the +content+.
      def initialize(name, content)
        @name, @content = name, content
      end

    end


    # Raised during parsing of data in Webgen Page Format if the data is invalid.
    class FormatError < Error; end


    # :stopdoc:
    RE_NEWLINE = /\r?\n/
    RE_META_INFO_START = /\A---\s*#{RE_NEWLINE}/
    RE_META_INFO = /#{RE_META_INFO_START}.*?#{RE_NEWLINE}(?=---.*?#{RE_NEWLINE}|\Z)/m
    RE_BLOCKS_START_SIMPLE = /^--- (\w+)(?:\s*| -+\s*)$|^$/
    RE_BLOCKS_START_COMPLEX = /^--- *?(?: *((?:\w+:[^\s]* *)*))?$|^$/
    RE_BLOCKS_START = /^---(?: .*?|)(?=#{RE_NEWLINE})/
    RE_BLOCKS = /(?:(#{RE_BLOCKS_START})|\A)#{RE_NEWLINE}?(.*?)(?:(?=#{RE_BLOCKS_START})|\z)/m
    RE_PAGE = /(#{RE_META_INFO})?(.*)/m
    # :startdoc:

    class << self

      # Parse the given string +data+ in Webgen Page Format. The +meta_info+ parameter can be used
      # to provide the default meta information hash.
      #
      # This method returns a Page object containing the (probably updated) meta information hash
      # and the parsed blocks.
      def from_data(data, meta_info = {})
        md = RE_PAGE.match(data)
        meta_info = meta_info.merge(parse_meta_info(md[1], data =~ RE_META_INFO_START))
        blocks = parse_blocks(md[2] || '', meta_info)
        new(meta_info, blocks)
      end

      # Parse the meta info string in +mi_data+ and return the hash with the meta information. The
      # original +data+ is used for checking the validness of the meta information block.
      def parse_meta_info(mi_data, has_mi_start)
        if mi_data.nil? && has_mi_start
          raise FormatError, 'Found start line for meta information block but no valid meta information block'
        elsif mi_data.nil?
          {}
        else
          begin
            meta_info = YAML::load(mi_data.to_s)
            unless meta_info.kind_of?(Hash)
              raise FormatError, "Invalid structure of meta information block: expected YAML hash but found #{meta_info.class}"
            end
          rescue ArgumentError, SyntaxError => e
            raise FormatError, "Invalid YAML syntax in meta information block: #{e.message}"
          end
          meta_info
        end
      end
      private :parse_meta_info

      # Parse all blocks in +data+ and return them. The key 'blocks' of the meta information hash is
      # used and probably updated with information found on block starting lines.
      def parse_blocks(data, meta_info)
        scanned = data.scan(RE_BLOCKS)
        raise(FormatError, 'No content blocks specified') if scanned.length == 0

        blocks = {}
        scanned.each_with_index do |block_data, index|
          index += 1
          options, content = *block_data
          if md = RE_BLOCKS_START_SIMPLE.match(options.to_s)
            options = {'name' => md[1]}
          else
            md = RE_BLOCKS_START_COMPLEX.match(options.to_s)
            raise(FormatError, "Found invalid blocks starting line for block #{index}: #{options}") if content =~ /\A---/ || md.nil?
            options = Hash[*md[1].to_s.scan(/(\w+):([^\s]*)/).map {|k,v| [k, (v == '' ? nil : YAML::load(v))]}.flatten]
          end

          options = (meta_info['blocks'][:default] || {} rescue {}).
            merge((meta_info['blocks'].delete(index) || {} rescue {})).
            merge(options)

          name = options.delete('name') || (index == 1 ? 'content' : 'block' + (index).to_s)
          raise(FormatError, "Previously used name '#{name}' also used for block #{index}") if blocks.has_key?(name)
          content ||= ''
          content.gsub!(/^(\\+)(---.*?)$/) {|m| "\\" * ($1.length / 2) + $2}
          content.chomp! unless index == scanned.length

          blocks[name] = Block.new(name, content)
          (meta_info['blocks'] ||= {})[name] = options unless options.empty?
        end
        meta_info['blocks'].delete(:default) if meta_info['blocks']
        meta_info.delete('blocks') if meta_info['blocks'] && meta_info['blocks'].empty?
        blocks
      end
      private :parse_blocks

    end


    # The contents of the meta information block.
    attr_reader :meta_info

    # The hash of blocks for the page.
    attr_reader :blocks

    # Create a new Page object with the meta information provided in +meta_info+ and the given
    # +blocks+.
    def initialize(meta_info = {}, blocks = {})
      @meta_info = meta_info
      @blocks = blocks
    end

  end

end
