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

require 'webgen/plugins/tags/tags'

module Webgen

  # Loads tag definitions from a file for project specific tags.
  class TagLoader < Plugin

    plugin "Tag Loader"
    summary "Loads tags from a configuration file"
    depends_on 'Tags'
    add_param 'tagconfig', 'tags.config', 'Configuration file for additional tags'

    def initialize
      @tags = {}
    end

    def parse_config_file
      if File.exists?( get_param( 'tagconfig' ) )
        begin
          instance_eval( File.read( get_param( 'tagconfig' ) ), get_param( 'tagconfig' ) )
        rescue Exception => e
          self.logger.error { "Error parsing file <#{get_param( 'tagconfig' )}>: #{e.message}" }
        end
      end
    end

    def simple_tag( name, processOutput = true, &block )
      register_tag( name, Tags::SimpleTag.new( processOutput, block ) )
    end

    def register_tag( name, processor )
      Plugin['Tags'].tags[name] = processor
    end

  end

end


module Tags

  class SimpleTag < DefaultTag

    VIRTUAL = true

    plugin "Simple Tag"
    summary "Used by the Tag Loader, provides the interface used by the Tags class"

    def initialize( processOutput, block )
      super()
      @processOutput = processOutput
      @block = block
    end

    def process_tag( tag, node, refNode )
      @block.call( tag, node, refNode )
    end

  end

end
