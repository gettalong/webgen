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

require 'set'
require 'webgen/listener'

module FileHandlers

  class FileHandler < Webgen::Plugin

    summary "Super plugin for handling files"
    description "Provides interface on file level. The FileHandler goes through the source
        directory, reads in all files for which approriate plugins exist and
        builds the tree. When all approriate transformations on the tree have
        been performed the FileHandler is used to write the output files.
      ".gsub( /^\s+/, '' ).gsub( /\n/, ' ' )
    add_param 'ignorePaths', ['**/.svn{/**/**,/}', '**/CVS{/**/**,/}'], 'An array of path patterns which match files that should ' \
    'be excluded from the list of \'to be processed\' files.'

    include Listener

    def initialize
      add_msg_name( :AFTER_ALL_READ )
      add_msg_name( :AFTER_ALL_WRITTEN )
    end

    # Builds the tree with all the nodes and returns it.
    def build_tree
      allFiles = get_files_for_pattern( File.join( '**', '{.[^.]**/**/**,**}' ) )
      get_param( 'ignorePaths' ).each do |pattern|
        allFiles.subtract( get_files_for_pattern( pattern ) )
      end

      handlerFiles = sort_file_handlers( FileHandlers::DefaultFileHandler.get_file_handlers ).collect do |pattern, handler|
        [get_files_for_pattern( pattern ), Webgen::Plugin.config[handler].obj]
      end

      rootPath = Webgen::Plugin['Configuration']['srcDirectory'] + File::SEPARATOR
      rootHandler = handler_for_path( rootPath, handlerFiles )
      if rootHandler.nil? || allFiles.empty?
        logger.error { "No file handler for root directory <#{rootPath}> found" } if rootHandler.nil? && !allFiles.empty?
        logger.error { "No files found in directory <#{rootPath}>" } if allFiles.empty?
        return nil
      end

      logger.debug { "Using plugin #{rootHandler.class.name} for handling the root node" }
      root = create_root_node( rootPath, rootHandler )
      allFiles.subtract( [rootPath] )
      handlerFiles.find {|files, handler| handler == rootHandler}[0].subtract( [rootPath] )

      handlerFiles.each do |files, handler|
        commonFiles = allFiles & files
        allFiles.subtract( commonFiles )
        diffFiles = files - commonFiles
        logger.info { "Not handling files for #{handler.class.name} as they do not exist or are excluded:  #{diffFiles.inspect}" } if diffFiles.length > 0
        commonFiles.each {|file| build_entry( file, root, handler, handlerFiles ) }
      end

      dispatch_msg( :AFTER_ALL_READ, root )
      logger.info { "No handlers found for files: #{allFiles.inspect}" } if allFiles.length > 0

      root
    end


    # Recursively writes out the tree specified by +node+.
    def write_tree( node )
      self.logger.info { "Writing <#{node.recursive_value('dest')}>" }

      node['processor'].write_node( node )

      node.each do |child|
        write_tree( child )
      end

      dispatch_msg( :AFTER_ALL_WRITTEN ) if node.parent.nil?
    end


    # Returns true if the file +src+ is newer than +dest+ and therefore has been modified since the last execution
    # of webgen. The +mtime+ values for the source and destination files are used to find this out.
    def file_modified?( src, dest )
      if File.exists?( dest ) && ( File.mtime( src ) < File.mtime( dest ) )
        self.logger.info { "File is up to date: <#{dest}>" }
        return false
      else
        return true
      end
    end

    #######
    private
    #######

    def get_files_for_pattern( pattern )
      files = Dir[File.join( Webgen::Plugin['Configuration']['srcDirectory'], pattern )].to_set
      files.collect!  do |f|
        f = f.sub( /([^.])\.{1,2}$/, '\1' ) # remove '.' and '..' from end of paths
        f += File::SEPARATOR if File.directory?( f ) && ( f[-1] != ?/ )
        f
      end
      files
    end

    def create_root_node( path, handler )
      root = handler.create_node( path, nil )
      root['title'] = ''
      root['dest'] = Webgen::Plugin['Configuration']['outDirectory'] + '/'
      root['src'] = Webgen::Plugin['Configuration']['srcDirectory'] + '/'
      root
    end

    def build_entry( file, root, handler, handlerFiles )
      pathname, filename = File.split( file )
      pathname = pathname + '/'
      treeFile = file.sub( /^#{root['src']}/, '' )
      treePath = pathname.sub( /^#{root['src']}/, '' )

      node = root.node_for_string?( treeFile, 'src' )
      return node unless node.nil?
      logger.info { "Processing <#{file}> with #{handler.class.name} ..." }

      parentNode = root.node_for_string?( treePath )
      if parentNode.nil?
        if pathname == root['src']
          parentNode = root
        else
          logger.debug { "Parent node for <#{file}> does not exist, create node for path <#{pathname}>" }
          parentNode = build_entry( pathname, root, handler_for_path( pathname, handlerFiles ), handlerFiles )
        end
      end
      raise "Parent node is nil" if parentNode.nil?
      logger.info { "Creating node for <#{file}>..." }
      n = handler.create_node( file, parentNode )
      parentNode.add_child( n ) unless n.nil?
      n
    end

    def handler_for_path( path, handlerFiles )
      temp, handler = handlerFiles.find {|p, handler| p.include?( path )}
      handler
    end

    def sort_file_handlers( handlers )
      handlers.sort {|a,b| a[0].count( "?*" ) <=> b[0].count( "?*" )}
    end

  end

  # The default handler which is the super class of all file handlers.
  class DefaultFileHandler < Webgen::Plugin

    summary "Base class of all file handler plugins"

    VIRTUAL = true

    # Specify the extension which should be handled by the class.
    def self.handle_path( path )
      logger.info { "Registering class #{self.name} for handling the path pattern: #{path.inspect}" }
      (self.config[self].path ||= []) << path
      handlers = (self.config[DefaultFileHandler].file_handler ||= {})
      logger.warn { "Path pattern #{path} already associated with class #{handlers[path].name}, not using class #{self.name} for it!" } if handlers[path]
      handlers[path] ||= self
    end

    # Specify the files handled by the class via the extension.
    def self.extension( ext )
      handle_path( "**/{.[^.]**/**/*.#{ext},*.#{ext}}" )
    end

    # Return the registered file handler plugins.
    def self.get_file_handlers
      self.config[self].file_handler
    end

    # Supplies the +path+ to a file and the +parent+ node sothat the plugin can create a node for this
    # path. Should return the node for the path or nil if the node could not be created.
    #
    # Has to be overridden by the subclass!!!
    def create_node( path, parent )
      raise NotImplementedError
    end

    # Asks the plugin to write out the node.
    #
    # Has to be overridden by the subclass!!!
    def write_node( node )
      raise NotImplementedError
    end

    # Returns the node for the language +lang+ which is equal to this +node+.
    def get_node_for_lang( node, lang )
      node
    end

    # Returns a HTML link for the given +node+ relative to +refNode+. You can optionally specify the
    # title for the link. If not specified, the title of the node is used.
    def get_html_link( node, refNode, title = node['title'] )
      "<a href=\"#{refNode.relpath_to_node( node )}\" title=\"#{title}\">#{title}</a>"
    end

  end

end
