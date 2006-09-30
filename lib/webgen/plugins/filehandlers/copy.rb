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

require 'fileutils'
require 'erb'
load_plugin 'webgen/plugins/filehandlers/filehandler'

module FileHandlers

  # A simple file handler which copies files specified by a pattern from the source to the output
  # directory.
  class CopyHandler < DefaultHandler

    plugin_name 'File/CopyHandler'
    infos :summary => "Copies files from source to destination without modification"
    param 'paths', ['**/*.css', '**/*.jpg', '**/*.png', '**/*.gif'], 'The path patterns ' +
      'which match the files that should get copied by this handler.'
    param 'erbPaths', ['**/*.rhtml', '**/*.rcss'], 'The path patterns which match the files ' +
      'that should get preprocessed by ERB. The leading letter r is removed from the extension.'

    def initialize( plugin_manager )
      super
      param( 'paths' ).each {|path| register_path_pattern( path ) }
      param( 'erbPaths' ).each {|path| register_path_pattern( path ) }
    end

=begin
TODO: move to doc
- file name is first checked against erbPaths, if a match -> erb processed (problem when same patterns in paths and erbPaths)
- node object is available when preprocessing with ERB
=end

    def create_node( path, parent, meta_info )
      processWithErb = param( 'erbPaths' ).any? {|pattern| File.fnmatch( pattern, path, File::FNM_DOTMATCH )}
      name = File.basename( path )
      name = name.sub( /\.r([^.]+)$/, '.\1' ) if processWithErb

      node = parent.find {|c| c =~ name }
      if node.nil?
        node = Node.new( parent, name )
        node['title'] = name
        node.meta_info.update( meta_info )
        node.node_info[:src] = path
        node.node_info[:processor] = self
        node.node_info[:preprocess] = processWithErb
      else
        log(:warn) { "Can't create node <#{node.full_path}> as it already exists (node handled by #{node.node_info[:processor].class.plugin_name})!" }
      end
      node
    end

    # Copy the file to the destination directory if it has been modified.
    def write_node( node )
      if @plugin_manager['Core/FileHandler'].file_modified?( node.node_info[:src], node.full_path )
        if node.node_info[:preprocess]
          File.open( node.full_path, 'w+' ) {|f| f.write( ERB.new( File.read( node.node_info[:src] ) ).result( binding ) ) }
        else
          FileUtils.cp( node.node_info[:src], node.full_path )
        end
      end
    end

  end

end
