require 'yaml'
require 'erb'

#TODO(adept docu) A single block within a page file. The content of the block gets automatically parsed for HTML
# headers with the id attribute set and converts them into sections for later use.
class Block

  # The name of the block.
  attr_reader :name

  # The content of the block.
  attr_reader :content

  attr_reader :options

  # Creates a new block with the name +name+ and the given +content+. The content gets parsed for
  # sections automatically.
  def initialize( name, content, options )
    @name, @content, @options = name, content, options
  end

  # context = { :chain => node_chain, :converters => {'webgentag' => WebgenTagConverter, 'erb' => ErbConverter, 'textile' => TextileConverter} }
  def render( context )
    temp = content
    @options['pipeline'].split(/;/).each do |converter|
      raise "No such content converter available: #{converter}" unless context[:converters].has_key?( converter )
      temp = context[:converters][converter].convert( temp, context, @options )
    end
    temp
  end

end


# Raised when during parsing of data in the WebPage Description Format if the data is invalid.
class PageInvalid < RuntimeError; end


#TODO(adept all docu) A Page object contains the parsed data of a file/string in the WebPage Format.
class Page

  RE_META_INFO_START = /\A---(?:\n|\r|\r\n)/m
  RE_META_INFO = /\A---(?:\n|\r|\r\n).*?(?:\n|\r|\r\n)(?=---.*?(?:\n|\r|\r\n))/m

  # The contents of the meta information block.
  attr_reader :meta_info

  # Parses the given String +data+ and initializes a new Page object with the found values.
  # The blocks are converted to HTML by using the provided +formatters+ hash. A key in this hash has
  # to be a format name and the value and object which responds to the +call(content)+ method. You
  # can set +default_meta_info+ to provide default entries for the meta information block.
  def initialize( meta_info = {}, blocks = nil, &block_proc )
    @meta_info = meta_info
    @blocks = blocks
    @blocks_creation_proc = block_proc
  end

  def self.create_from_file( file, meta_info = {} )
    if File.size( file ) <= 1024
      create_from_data( File.read( file ), meta_info )
    else
      file_pos = 0
      File.open( file, 'r' ) do |fd|
        data = fd.read( 1024 )
        if data =~ RE_META_INFO_START
          data << fd.read(1024) while !(md = RE_META_INFO.match( data )) && !fd.eof?
          raise( PageInvalid, 'Invalid structure of meta information part') if md.nil?
          meta_info = meta_info.merge( parse_meta_info( normalize_eol( md[0] ) ) )
          file_pos = md[0].length
        end
      end
      self.new( meta_info ) do
        blocks = ''
        File.open( file, 'r' ) do |fd|
          fd.seek( file_pos )
          blocks = parse_blocks( normalize_eol( fd.read ), meta_info )
        end
        blocks
      end
    end
  end

  # Handle case where meta info is invalid "---\nasdfasdfsdf" (no more \n---\n)!
  def self.create_from_data( data, meta_info = {} )
    md = /(#{RE_META_INFO})?(.*)/m.match( normalize_eol( data ) )
    raise( PageInvalid, 'Invalid structure of meta information part') if md[1].nil? && data =~ RE_META_INFO_START
    meta_info = meta_info.merge( parse_meta_info( md[1] ) ) if !md[1].nil?
    blocks = parse_blocks( md[2] || '', meta_info )
    self.new( meta_info, blocks )
  end

  def blocks
    @blocks = @blocks_creation_proc.call if @blocks.nil? && !@blocks_creation_proc.nil?
    @blocks
  end

  #######
  private
  #######

  def self.normalize_eol( data )
    data.gsub( /\r\n?/, "\n" )
  end

  def self.parse_meta_info( data )
    begin
      meta_info = YAML::load( data )
      raise( PageInvalid, 'Invalid structure of meta information part') unless meta_info.kind_of?( Hash )
    rescue ArgumentError => e
      raise PageInvalid, e.message
    end
    meta_info
  end

  #TODO enable parsing of --- name, format:data, test:data, key:value
  #blocks:
  #  default:           # default values for all blocks
  #    format: textile
  #    pipeline: doit;haus;end
  #  entries:           # indiv entries for blocks, use ~ (nil) to not set name or options
  #    - [name, {format:textile, pipeline:doit}]
  def self.parse_blocks( data, meta_info )
    scanned = data.scan( /(?:(?:^--- *(?:(\w+) *((?:, *\w+:[^\s,]+ *)*))?$)|\A)(.*?)(?:(?=^--- *(?:(?:\w+) *(?:(?:, *\w+:[^\s,]+ *)*))?$)|\Z)/m )
    raise( PageInvalid, 'No content blocks specified' ) if scanned.length == 0

    blocks = {}
    scanned.each_with_index do |block_data, index|
      name, options, content = *block_data
      raise( PageInvalid, "Found invalid blocks starting line" ) if content =~ /^---/
      name = name || (meta_info['blocks']['entries'][index][0] rescue nil) || (index == 0 ? 'content' : 'block' + (index + 1).to_s)
      raise( PageInvalid, "Same name used for more than one block: #{name}" ) if blocks.has_key?( name )
      content ||= ''
      content.gsub!( /^(\\+)(---.*?)$/ ) {|m| "\\" * ($1.length / 2) + $2 }
      content.strip!
      options = (meta_info['blocks']['default'] rescue {}).
        merge( (meta_info['blocks']['entries'][index][1] rescue {}) ).
        merge( (!options.nil? && Hash[*options.scan(/(\w+):([^\s,]+)/).flatten]) || {} )
      blocks[name] = blocks[index+1] = Block.new( name, content, options )
    end
    blocks
  end

end
