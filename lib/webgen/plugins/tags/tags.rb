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

  # This is the main class for tags. Tag plugins can register themselves by adding a new key:value
  # pair to +tags+. The key has to be the name of the tag as specified in the page description files
  # and the value is the plugin object itself. When the content is parsed and a tag is
  # encountered, the registered plugin for the tag is called. If no plugin for a tag is registered
  # but a default plugin is, the default plugin is called. Otherwise an error is raised.
  #
  # The default plugin can be registered by using the special key <tt>:default</tt>.
  class Tags < UPS::Plugin

    NAME = "Tags"
    SHORT_DESC = "Super plugin for handling tags"

    Webgen::WebgenError.add_entry :UNKNOWN_TAG,
      "found tag {%0: ...} for which no plugin exists",
      "either remove the tag or implement a plugin for it"


    # Tag plugins should add an entry to this hash.
    attr_accessor :tags

    def initialize
      @tags = Hash.new
    end


    # Substitutes all references to tags in the string +content+. The +node+ parameter specifies the
    # tree node the content of which is used. The +refNode+ parameter specifies relative to which
    # all references should be resolved.
    def substitute_tags( content, node, refNode )
      content.to_s.gsub!(/(\\*)(\{(\w+):\s+(\{.*?\}|.*?)\})/) do |match|
        nrBackslash = $1.length / 2
        if $1.length % 2 == 1
          "\\"*nrBackslash + $2
        else
          tagValue = YAML::load( "- #{$4}" )[0]
          self.logger.info { "Replacing tag #{match} in <#{node.recursive_value( 'dest' )}>" }
          if @tags.has_key? $3
            tagProcessor = @tags[$3]
          elsif @tags.has_key? :default
            tagProcessor = @tags[:default]
          else
            raise Webgen::WebgenError.new( :UNKNOWN_TAG, $3 )
          end
          "\\"*nrBackslash + substitute_tags( tagProcessor.process_tag( $3, tagValue, node, refNode ), node, node )
        end
      end
      content
    end

  end


  UPS::Registry.register_plugin Tags

end
