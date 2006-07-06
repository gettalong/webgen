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

require 'webgen/config'

module Webgen

  # Describes a human language which is uniquely identfied by a three letter code and, optionally,
  # by an alternative three letter or a two letter code.
  class Language

    include Comparable

    attr_reader :codes
    attr_reader :description

    # Creates a new language. +codes+ has to be an array containing three strings: the three letter
    # code, the alternative three letter code and the two letter code. If one is not available for
    # the language, it has to be +nil+.
    def initialize( codes, description )
      @codes = codes
      @description = description
    end

    # The two letter code.
    def code2chars
      @codes[2]
    end

    # The three letter code.
    def code3chars
      @codes[0]
    end

    # The alternative three letter code.
    def code3chars_alternative
      @codes[1]
    end

    # The textual representation of the language.
    def to_s
      code2chars || code3chars
    end

    alias_method :to_str, :to_s

    def inspect
      "#<Language codes=#{codes.inspect} description=#{description.inspect}"
    end

    def <=>( other )
      self.to_s <=> other.to_s
    end

  end


  # Used for managinging human languages.
  module LanguageManager

    # Returns a +Language+ object for the given language code.
    def self.language_for_code( code )
      languages[code]
    end

    # Returns an array of +Language+ objects whose description match the given +text+.
    def self.find_language( text )
      languages.values.find_all {|lang| /.*#{Regexp.escape(text)}.*/i =~ lang.description}.uniq.sort
    end

    # Returns all available languages as a Hash. The keys are the language codes and the values are
    # the +Language+ objects for them.
    def self.languages
      unless defined?( @@languages )
        @@languages = {}
        code_file = File.join( Webgen.data_dir, 'data', 'ISO-639-2_values_8bits.txt' )
        File.readlines( code_file ).each do |l|
          data = l.chomp.split( '|' ).collect {|f| f.empty? ? nil : f }
          lang = Language.new( data[0..2], data[3] )
          @@languages[lang.code2chars] ||= lang
          @@languages[lang.code3chars] ||= lang
          @@languages[lang.code3chars_alternative] ||= lang
        end
        @@languages.freeze
      end
      @@languages
    end

  end

end
