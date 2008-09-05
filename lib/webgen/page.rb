require 'yaml'

module Webgen

  # A single block within a Page object. The content of the block can be rendered using the #render method.
  class Block

    # The name of the block.
    attr_reader :name

    # The content of the block.
    attr_reader :content

    # The options set specifically for this block.
    attr_reader :options

    # Create a new block with the name +name+ and the given +content+ and +options+.
    def initialize(name, content, options)
      @name, @content, @options = name, content, options
    end

    # Render the block using the provided context object. Uses the content processors specified in
    # the +pipeline+ key of the +options+ attribute to do the actual rendering.
    #
    # Returns the given context with the rendered content.
    def render(context)
      context[:content] = @content.dup
      context[:block] = self
      @options['pipeline'].to_s.split(/,/).each do |processor|
        raise "No such content processor available: #{processor}" unless context[:processors].has_key?(processor)
        context[:processors][processor].call(context)
      end
      context
    end

  end


  # Raised during parsing of data in Webgen Page Format if the data is invalid.
  class WebgenPageFormatError < RuntimeError; end

  # A Page object wraps a meta information hash and an array of Block objects. It is normally
  # generated from a file or string in Webgen Page Format using the provided class methods.
  class Page

    RE_META_INFO_START = /\A---\s*(?:\n|\r|\r\n)/m
    RE_META_INFO = /\A---\s*(?:\n|\r|\r\n).*?(?:\n|\r|\r\n)(?=---.*?(?:\n|\r|\r\n)|\Z)/m
    RE_BLOCKS_OPTIONS = /^--- *?(?: *((?:\w+:[^\s]* *)*))?$|^$/
    RE_BLOCKS_START = /^--- .*?$|^--- *$/
    RE_BLOCKS = /(?:(#{RE_BLOCKS_START})|\A)(.*?)(?:(?=#{RE_BLOCKS_START})|\Z)/m

    class << self

      # Parse the given string +data+ in Webgen Page Format and initialize a new Page object with
      # the information. The +meta_info+ parameter can be used to provide default meta information.
      def from_data(data, meta_info = {})
        md = /(#{RE_META_INFO})?(.*)/m.match(normalize_eol(data))
        if md[1].nil? && data =~ RE_META_INFO_START
          raise WebgenPageFormatError, 'Found start line for meta information block but no valid meta information block'
        end
        meta_info = meta_info.merge(md[1].nil? ? {} : parse_meta_info(md[1]))
        blocks = parse_blocks(md[2] || '', meta_info)
        new(meta_info, blocks)
      end

      #######
      private
      #######

      # Normalize the end-of-line encodings to Unix style.
      def normalize_eol(data)
        data.gsub(/\r\n?/, "\n")
      end

      # Parse the meta info string +data+ and return the hash with the meta information.
      def parse_meta_info(data)
        begin
          meta_info = YAML::load(data)
          unless meta_info.kind_of?(Hash)
            raise WebgenPageFormatError, "Invalid structure of meta information block: expected YAML hash but found #{meta_info.class}"
          end
        rescue ArgumentError => e
          raise WebgenPageFormatError, e.message
        end
        meta_info
      end

      # Parse all blocks in +data+ and return them. Meta information can be provided in +meta_info+
      # which is used for setting the block names and options.
      def parse_blocks(data, meta_info)
        scanned = data.scan(RE_BLOCKS)
        raise(WebgenPageFormatError, 'No content blocks specified') if scanned.length == 0

        blocks = {}
        scanned.each_with_index do |block_data, index|
          options, content = *block_data
          md = RE_BLOCKS_OPTIONS.match(options.to_s)
          raise(WebgenPageFormatError, "Found invalid blocks starting line for block #{index+1}: #{options}") if content =~ /\A---/ || md.nil?
          options = Hash[*md[1].to_s.scan(/(\w+):([^\s]*)/).map {|k,v| [k, YAML::load(v)]}.flatten]
          options = (meta_info['blocks']['default'] || {} rescue {}).
            merge((meta_info['blocks'][index+1] || {} rescue {})).
            merge(options)

          name = options.delete('name') || (index == 0 ? 'content' : 'block' + (index + 1).to_s)
          raise(WebgenPageFormatError, "Previously used name '#{name}' also used for block #{index+1}") if blocks.has_key?(name)
          content ||= ''
          content.gsub!(/^(\\+)(---.*?)$/) {|m| "\\" * ($1.length / 2) + $2}
          content.strip!
          blocks[name] = blocks[index+1] = Block.new(name, content, options)
        end
        meta_info.delete('blocks')
        blocks
      end

    end


    # The contents of the meta information block.
    attr_reader :meta_info

    # The array of blocks for the page.
    attr_reader :blocks

    # Create a new Page object with the meta information provided in +meta_info+ and the given
    # +blocks+.
    def initialize(meta_info = {}, blocks = nil)
      @meta_info = meta_info
      @blocks = blocks
    end

  end

end
