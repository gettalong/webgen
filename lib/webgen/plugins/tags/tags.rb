#
#--
#
# $Id$
#
# webgen: a template based web page generator
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
require 'util/ups'

module Tags

  class Tags < UPS::Plugin

    NAME = "Tags"
    SHORT_DESC = "Super plugin for handling tags"

    Webgen::WebgenError.add_entry :UNKNOWN_TAG,
      "found tag {%0: ...} for which no plugin exists",
      "either remove the tag or implement a plugin for it"

    attr_accessor :tags

    def initialize
      @tags = Hash.new
    end


    def substitute_tags( content, node, refNode )
      content.to_s.gsub!(/\{(\w+):\s+(\{.*?\}|.*?)\}/) do |match|
        tagValue = YAML::load( "- #{$2}" )[0]
        self.logger.info { "Replacing tag #{match} in <#{node.recursive_value( 'dest' )}>" }
        if @tags.has_key? $1
          tagProcessor = @tags[$1]
        elsif @tags.has_key? :default
          tagProcessor = @tags[:default]
        else
          raise Webgen::WebgenError.new( :UNKNOWN_TAG, $1 )
        end
        substitute_tags( tagProcessor.process_tag( $1, tagValue, node, refNode ), node, node )
      end
      content
    end

  end


  UPS::Registry.register_plugin Tags

end
