#
#--
#
# $Id$
#
# webgen: template based static website generator
# Copyright (C) 2004 Thomas Leitner
#
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU
# General Public License as published by the Free Software Foundation; either version 2 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
# even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with this program; if not,
# write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#
#++
#

require 'yaml'
require 'erb'

# A single block within a page file. The content of the block gets automatically parsed for HTML
# headers with the id attribute set and converts them into sections for later use.
class HtmlBlock

  # A section with a block. Corresponds to an HTML header with an id.
  class Section

    # The level of the header, ie. 1 for a h1 tag, 2, for a h2 tag, and so on.
    attr_reader :level

    # The id of the tag.
    attr_reader :id

    # The title of the tag, ie. the content between the opening and closing h[123456] tag.
    attr_reader :title

    # Sub sections of this section.
    attr_accessor :subsections

    # Creates a new Section object with the given +level+, +id+, and +title+.
    def initialize( level, id, title )
      @level, @id, @title = level, id, title
      @subsections = []
    end

  end

  # The name of the block.
  attr_reader :name

  # The content of the block.
  attr_reader :content

  # The parsed sections as array of Section objects.
  attr_reader :sections

  # Creates a new block with the name +name+ and the given +content+. The content gets parsed for
  # sections automatically.
  def initialize( name, content )
    @name, @content = name, content
    @sections = self.class.parse_sections( content )
  end

  # Renders the block using ERB and +context+ as the binding.
  def render_with_erb( context )
    ERB.new( content ).result( context )
  end

  #######
  private
  #######

  SECTION_REGEXP = /<h([123456])(?:>|\s([^>]*)>)(.*?)<\/h\1\s*>/i
  ATTR_REGEXP = /\s*(\w+)\s*=\s*('|")([^\2]+)\2\s*/

  def self.parse_sections( content )
    sections = []
    stack = []
    content.scan( SECTION_REGEXP ).each do |level,attrs,title|
      next if attrs.nil?
      id_attr = attrs.scan( ATTR_REGEXP ).find {|name,sep,value| name == 'id'}
      next if id_attr.nil?
      id = id_attr[2]

      section = Section.new( level.to_i, id, title )
      success = false
      while !success
        if stack.empty?
          sections << section
          stack << section
          success = true
        elsif stack.last.level < section.level
          stack.last.subsections << section
          stack << section
          success = true
        else
          stack.pop
        end
      end
    end
    sections
  end

end


# Raised when during parsing of data in the WebPage Description Format if the data is invalid.
class WebPageDataInvalid < RuntimeError; end


# A WebPageData object contains the parsed data of a file/string in the WebPage Description Format.
class WebPageData

  # The content blocks. Access via index or name.
  attr_reader :blocks

  # The contents of the meta information block.
  attr_reader :meta_info

  # Parses the given String +data+ and initializes a new WebPageData object with the found values.
  # The blocks are converted to HTML by using the provided +formatters+ hash. A key in this hash has
  # to be a format name and the value and object which responds to the +call(content)+ method. You
  # can set +default_meta_info+ to provide default entries for the meta information block.
  def initialize( data, formatters = {'default' => proc {|c| c} }, default_meta_info = {} )
    @meta_info = default_meta_info
    @formatters = formatters
    parse( data )
  end

  #######
  private
  #######

=begin
TODO: MOVE TO DOC
- format is called WebPage Description Format, a file using this format is called a page file
- page file consists of optionally one meta info block at beginning, 1 to n content blocks
- meta info block is YAML
- default name for block if none specified (ie. no explicit name in --- line or in blocks meta info of correct index) is 'content' (precedence (low to high): default , --- line, blocks meta info)
- default for block format (ie. if non in --- line or in blocks meta info of correct index) called 'default'
- block names have to be unique
- escaped block separators in blocks are unescaped and leading/trailing whitespace stripped off
=end


  def parse( data )
    @blocks = {}
    blocks = data.scan( /(?:(?:^--- *(?:(\w+) *(?:, *(\w+) *)?)?$)|\A)(.*?)(?:(?=^---.*?$)|\Z)/m )
    if data =~ /\A---/
      begin
        meta = YAML::load( blocks.shift[2] )
        raise( WebPageDataInvalid, 'Invalid structure of meta information part') unless meta.kind_of?( Hash )
        @meta_info.update( meta )
      rescue ArgumentError => e
        raise WebPageDataInvalid, e.message
      end
    end

    raise( WebPageDataInvalid, 'No content blocks specified' ) if blocks.length == 0

    blocks.each_with_index do |block_data, index|
      name, format, content = *block_data
      name = (@meta_info['blocks'] && @meta_info['blocks'][index] && @meta_info['blocks'][index]['name']) || name || 'content'
      raise( WebPageDataInvalid, "Same name used for more than one block: #{name}" ) if @blocks.has_key?( name )
      content ||= ''
      content.gsub!( /^(\\+)(---.*?)$/ ) {|m| "\\" * ($1.length / 2) + $2 }
      content.strip!
      format = (@meta_info['blocks'] && @meta_info['blocks'][index] && @meta_info['blocks'][index]['format']) || format || 'default'
      @blocks[name] = @blocks[index] = HtmlBlock.new( name, convert( content, format ) )
    end
  end

  def convert( content, format )
    raise( WebPageDataInvalid, "Invalid content format specified: #{format}" ) unless @formatters.has_key?( format )
    @formatters[format].call( content )
  end

end
