# -*- encoding: utf-8 -*-

require 'webgen/path_handler'
require 'webgen/error'
require 'webgen/node'
require 'webgen/path'

module Webgen
  class PathHandler

    # This module provides the helper methods needed by most, if not all, path handlers.
    #
    # The most important method when implementing a path handler is #create_node which is used to
    # create the actual Webgen::Node object from a Webgen::Path object.
    module Base

      # Initialize the path handler with the given Website object.
      def initialize(website)
        @website = website
      end

      # Return the content of the given +node+. If the return value is not +nil+ then the node gets
      # written, otherwise it is ignored.
      #
      # This default +content+ method just returns +nil+.
      def content(node)
      end

      # Update +path.meta_info+ with meta information found in the content of the path.
      #
      # This default +parse_meta_info!+ method does nothing and should be overridden in path
      # handlers that know that additional meta information can be found in the content of the path
      # itself. Note that the return values of this method are given as extra parameters to the
      # #create_nodes method. If you don't handle extra parameters, return an empty array.
      def parse_meta_info!(path)
        []
      end

      # Create a node from +path+ if it does not already exists or re-initalize an already existing
      # node. The found node or the newly created node is returned afterwards. +nil+ is returned if no
      # node can be created (e.g. when <tt>path.meta_info['draft']</tt> is set).
      #
      # The parent node under which the new node should be created can be set via the +parent+
      # parameter. If this is not specified (the usual case), the parent node is determined by the
      # #parent_node method.
      #
      # Some additional node information like <tt>:src</tt> and <tt>:processor</tt> are set and the
      # meta information is checked for validness. The created node is yielded if a block is given.
      def create_node(path, parent = nil)
        return nil if path.meta_info['draft']
        parent ||= parent_node(path)
        dest_path = self.dest_path(parent, path)

        if node = node_exists?(parent, path, dest_path)
          raise Webgen::NodeCreationError.new("Another node <#{node}> with the same alcn or destination path already exists")
        end

        if !path.meta_info['modified_at'].kind_of?(Time)
          @website.logger.warn do
            "Meta information 'modified_at' set to current time in <#{path}> since its value '#{path.meta_info['modified_at']}' was of type #{path.meta_info['modified_at'].class}"
          end unless path.meta_info['modified_at'].nil?
          path.meta_info['modified_at'] = Time.now
        end

        node = Webgen::Node.new(parent, path.cn, dest_path, path.meta_info)
        node.node_info[:src] = path.source_path
        node.node_info[:creation_path] = path.path

        yield(node) if block_given?
        node
      end
      protected :create_node

      # Return the parent node for the given +path+.
      def parent_node(path)
        parent_dir = (path.parent_path == '' ? '' : Webgen::Path.new(path.parent_path).alcn)
        if !(parent = @website.tree[parent_dir])
          raise Webgen::NodeCreationError.new("The needed parent node <#{parent_dir}> does not exist")
        end
        parent
      end
      protected :parent_node

      # Construct the destination path for the given +path+ and +parent+ node.
      #
      # First it is checked if a node with the constructed destination path already exists. If it
      # exists, the language part is forced to be in the destination path and the resulting
      # destination path is returned.
      def dest_path(parent, path)
        dpath = construct_dest_path(parent, path, false)
        if (node = node_exists?(parent, path, dpath)) && node.lang != path.meta_info['lang']
          dpath = construct_dest_path(parent, path, true)
        end
        dpath
      end
      protected :dest_path

      PARENT_SEGMENTS = /:parent\[(-?\d+)(?:..(-?\d+))?\]/ # :nodoc:

      # Construct the destination path from the parent node and the path.
      def construct_dest_path(parent, path, force_lang_part)
        unless path.meta_info['dest_path'].kind_of?(String)
          raise Webgen::NodeCreationError.new("Invalid meta info 'dest_path', must be a string")
        end
        dest_path = path.meta_info['dest_path'].dup

        if dest_path.start_with?('webgen:')
          dest_path.gsub!(/^webgen:/, '')
        elsif dest_path !~ /^[\w+.-]+:/
          parent = parent.parent while parent.is_fragment?
          parent_segments = parent.dest_path.split('/')[1..-1] || []
          use_lang_part = if path.meta_info['lang'].nil? # unlocalized files never get a lang in the filename!
                            false
                          elsif force_lang_part
                            true
                          elsif @website.config['path_handler.lang_code_in_dest_path'] == 'except_default_lang'
                            @website.config['website.lang'] != path.meta_info['lang']
                          else
                            @website.config['path_handler.lang_code_in_dest_path']
                          end

          dest_path.gsub!((use_lang_part ? /[()]/ : /\(.*?\)/), '')
          dest_path.gsub!(/#{PARENT_SEGMENTS}|:[a-zA-Z]+@?/) do |match|
            case match
            when PARENT_SEGMENTS
              nr1 = adjust_index($1.to_i)
              (nr2 = adjust_index($2.to_i)) if $2
              [parent_segments[nr2 ? nr1..nr2 : nr1]].flatten.compact.join('/')
            when /:parent@?/
              parent.dest_path
            when /:basename@?/
              path.basename
            when /:ext@?/
              path.ext.empty? ? '' : '.' << path.ext
            when /lang@?/
              use_lang_part ? path.meta_info['lang'] : ''
            when /:(year|month|day)@?/
              ctime = path.meta_info['created_at']
              if !ctime.kind_of?(Time)
                raise Webgen::NodeCreationError.new("Invalid meta info 'created_at', needed for destination path creation")
              end
              ctime.send($1).to_s.rjust(2, '0')
            else
              match
            end
          end
          dest_path += '/' if path.path =~ /\/$/
          dest_path.gsub!(/\/\/+/, '/')
        end

        dest_path
      end
      private :construct_dest_path

      # Consider the number +index+ to be 1-based and convert it to a 0-based index needed for Ruby
      # arrays.
      #
      # An error is raised if the index is equal to 0.
      def adjust_index(index)
        if index > 0
          index - 1
        elsif index == 0
          raise Webgen::NodeCreationError.new("Invalid meta info 'dest_path', index into parent segments must not be 0")
        else
          index
        end
      end
      private :adjust_index

      # Check if the node alcn or the destination path which would be created by #create_node exists.
      def node_exists?(parent, path, dest_path = self.dest_path(parent, path))
        @website.tree[path.alcn] || (!path.meta_info['no_output'] && @website.tree[dest_path, :dest_path])
      end
      protected :node_exists?

    end

  end

end
