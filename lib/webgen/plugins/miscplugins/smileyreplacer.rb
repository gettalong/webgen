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

load_plugin 'webgen/plugins/filehandlers/page'
load_plugin 'webgen/plugins/coreplugins/resourcemanager'

module MiscPlugins

  class SmileyReplacer < Webgen::Plugin

    plugin_name 'Misc/SmileyReplacer'
    infos :summary => "Replaces smiley characters with actual smileys"
    depends_on 'File/PageHandler'

    param 'emoticonPack', nil, 'The name of the emoticon package which should be used. If set to nil, ' +
      'smileys are not replaced.'

=begin
TODO: move to doc
- uses metainfo 'emoticonPack'
=end

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

    def initialize( plugin_manager )
      super
      @plugin_manager['File/PageHandler'].add_msg_listener( :after_content_rendered, method( :replace_smileys ) )
    end

    #######
    private
    #######

    def replace_smileys( content, node )
      pack = smiley_pack( node )
      return content if pack.nil?

      log(:info) { "Replacing smileys in file <#{node.full_path}>..." }
      content.gsub!( SMILEY_REGEXP ) do |match|
        log(:info) { "Found smiley #{match}, trying to replace it with emoticon..." }
        if res = @plugin_manager['Core/ResourceManager'].get_resource( "webgen-emoticons-#{pack}-#{SMILEY_MAP[match]}" )
          res.referenced!
          "<img src=\"#{res.route_from( node )}\" alt=\"smiley #{match}\" />"
        else
          log(:warn) { "Could not replace smiley '#{match}'(name: #{SMILEY_MAP[match]}, pack: #{pack}) in <#{node.full_path}>: resource not found!" }
          match
        end
      end
    end

    def smiley_pack( node )
      node.meta_info.has_key?( 'emoticonPack' ) && node['emoticonPack'].nil? ? nil : node['emoticonPack'] || param( 'emoticonPack' )
    end

  end

end
