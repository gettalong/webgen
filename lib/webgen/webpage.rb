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

# Raised when during parsing of data in the WebPage Description Format if the data is invalid.
class WebPageDataInvalid < RuntimeError; end

# A WebPageData object contains the parsed data of a file/string in the WebPage Description Format.
class WebPageData

  class Block

    attr_accessor :name
    attr_accessor :format
    attr_accessor :content

    def initialize( name, format, content )
      @name, @format, @content = name, format, content
    end

  end

  # The content blocks. Access via index or name.
  attr_reader :blocks

  # The contents of the meta information block.
  attr_reader :meta_info

  # See WebPageData.parse.
  def initialize( data )
    @meta_info = {}
    parse( data )
  end

  # Parses the given String +data+ and initializes a new WebPageData object with the found values.
  def self.parse( data )
    self::new( data )
  end

  #######
  private
  #######

=begin
TODO: MOVE TO DOC
- format is called WebPage Description Format, a file using this format is called a page file
- page file consists of optionally one meta info block at beginning, 1 to n content blocks
- meta info block is YAML
- default name for block if none specified is 'content'
- no default for block formats (none specified -> variable is nil)
- block names have to be unique
- escaped block separators in blocks are unescaped and leading/trailing whitespace stripped off
=end


  def parse( data )
    @blocks = {}
    blocks = data.scan( /(?:(?:^--- *(?:(\w+) *(?:, *(\w+) *)?)?$)|\A)(.*?)(?:(?=^---.*?$)|\Z)/m )
    if data =~ /\A---/
      begin
        @meta_info = YAML::load( blocks.shift[2] )
        raise( WebPageDataInvalid, 'invalid structure of the meta information part') unless @meta_info.kind_of?( Hash )
      rescue ArgumentError => e
        raise WebPageDataInvalid, e.message
      end
    end

    raise( WebPageDataInvalid, 'no content block specified' ) if blocks.length == 0

    blocks.each_with_index do |block_data, index|
      name, format, content = *block_data
      name = 'content' if name.nil?
      raise( WebPageDataInvalid, 'same name for different blocks' ) if @blocks.has_key?( name )
      content ||= ''
      content.gsub!( /^(\\+)(---.*?)$/ ) {|m| "\\" * ($1.length / 2) + $2 }
      content.strip!
      @blocks[name] = @blocks[index] = Block.new( name, format, content )
    end
  end

end
