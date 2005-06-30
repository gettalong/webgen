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

require 'webgen/plugins/filehandler/filehandler'
require 'webgen/plugins/resourcemanager'

module OtherPlugins

  class SmileyReplacer < Webgen::Plugin

    summary "Replaces smiley characters with actual smileys"
    depends_on 'FileHandler', 'ResourceManager'

    add_param 'emoticonPack', nil, 'The name of the emoticon package which should be used. If set to nil, ' \
    'smileys are not replaced.'

    used_meta_info 'emoticonPack'

    SMILEY_MAP = {
      ':-@' => 'angry',
      '8-)' => 'cool',
      ':\'-(' => 'cry',
      ':*)' => 'drunk',
      ':-D' => 'lol',
      ':-O' => 'oops',
      ':-(' => 'sad',
      '|-I' => 'sleep',
      ':-)' => 'smile',
      ':-P' => 'tongue',
      ';-)' => 'wink'
    }
    SMILEY_REGEXP = Regexp.union( *SMILEY_MAP.keys.collect {|t| /#{Regexp.escape(t)}/ } )

    def initialize
      Webgen::Plugin['PageHandler'].add_msg_listener( :AFTER_CONTENT_RENDERED, method( :replace_smileys ) )

      Dir[File.join( Webgen::Configuration.data_dir, 'resources', 'emoticons', '*/')].each do |pack_dir|
        pack = File.basename( pack_dir )
        Dir[File.join( pack_dir, '*' )].each do |smiley_file|
          smiley = File.basename( smiley_file, '.*' )
          res = Webgen::Plugin['ResourceManager'].define_file_resource( emoticon_resource_name( pack, smiley ),
                                                                        smiley_file,
                                                                        "/images/emoticon/#{pack}-#{File.basename(smiley_file)}" )
          res.predefined = "Emoticon from pack '#{pack}' for '#{smiley}'"
        end
      end
    end

    def emoticon_resource_name( pack, name )
      "webgen-emoticon-#{pack}-#{name}"
    end

    #######
    private
    #######

    def replace_smileys( content, node )
      pack = smiley_pack( node )
      return if pack.nil?

      logger.info { "Replacing smileys in file <#{node.recursive_value('dest')}>..." }
      content.gsub!( SMILEY_REGEXP ) do |match|
        logger.info { "Found smiley #{match}, trying to replace it with emoticon..." }
        if res = Webgen::Plugin['ResourceManager'].get_resource( emoticon_resource_name( pack, SMILEY_MAP[match] ) )
          res.referenced!
          "<img src=\"#{res.relpath_from_node( node )}\" alt=\"smiley #{match}\" />"
        else
          logger.warn { "Could not replace smiley '#{match}'(#{SMILEY_MAP[match]}) in <#{node.recursive_value('src')}>: resource not found!" }
          match
        end
      end
    end

    def smiley_pack( node )
      node.metainfo.has_key?( 'emoticonPack' ) && node['emoticonPack'].nil? ? nil : node['emoticonPack'] || get_param( 'emoticonPack' )
    end

  end

end
