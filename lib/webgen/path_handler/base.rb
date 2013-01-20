# -*- encoding: utf-8 -*-

require 'webgen/path_handler'
require 'webgen/error'
require 'webgen/node'
require 'webgen/path'
require 'webgen/utils'

module Webgen
  class PathHandler

    # This module provides the helper methods needed by most, if not all, path handlers.
    #
    # == About
    #
    # It provides default implementations of all methods expected by Webgen::PathHandler except
    # #create_nodes, namely #initialize, #parse_meta_info! and #content.
    #
    # The most important method used when implementing a path handler is probably #create_node which
    # should be used in #create_nodes to create an actual Webgen::Node object from a Webgen::Path
    # object.
    #
    # The following utility methods are also provided:
    #
    # * #parent_node
    # * #dest_path
    # * #node_exists?
    #
    module Base

      # This is the Node sub class used by the Base#create_node method if a path handler class does
      # not specify another Node class.
      class Node < Webgen::Node

        # Does exactly the same as Node#route_to but also automatically adds the necessary item
        # tracking information.
        def route_to(node, lang = @lang)
          tree.website.ext.item_tracker.add(self, :node_meta_info, node)
          tree.website.ext.item_tracker.add(self, :node_meta_info, node.proxy_node(lang))
          super
        end

        # Return the result of the #content method on the associated path handler or +nil+ if the
        # associated path handler does not have a #content method.
        def content
          (@node_info[:path_handler].respond_to?(:content) ? @node_info[:path_handler].content(self) : nil)
        end

      end


      # Initialize the path handler with the given Website object.
      def initialize(website)
        @website = website
      end

      # Update +path.meta_info+ with meta information found in the content of the path.
      #
      # This default +parse_meta_info!+ method does nothing and should be overridden in path
      # handlers that know that additional meta information can be found in the content of the path
      # itself.
      #
      # Note that the return values of this method are given as extra parameters to the
      # #create_nodes method. If you don't handle extra parameters, return an empty array.
      def parse_meta_info!(path)
        []
      end

      # Create a node from +path+, if possible, yield the fully initialized node if a block is given
      # and return it.
      #
      # The node class to be used for the to-be-created node can be specified via
      # `path.meta_info['node_class']`. If this node processing information is not set, the
      # Base::Node class is used.
      #
      # The parent node under which the new node should be created can optionally be specified via
      # 'path.meta_info['parent_alcn']'. This node processing information has to be set to the alcn
      # of an existing node.
      #
      # If no node can be created (e.g. when 'path.meta_info['draft']' is set), +nil+ is returned.
      #
      # On the created node, the node information +:path+ is set to the given path and
      # +:path_handler+ to the path handler instance.
      def create_node(path)
        return nil if path.meta_info['draft']
        parent = parent_node(path)
        dest_path = self.dest_path(parent, path)

        if node = node_exists?(path, dest_path)
          node_path = node.node_info[:path]
          if node_path != path
            raise Webgen::NodeCreationError.new("Another node <#{node}> with the same alcn or destination path already exists")
          elsif node_path.meta_info == path.meta_info
            @website.blackboard.dispatch_msg(:reused_existing_node, node)
            return node
          else
            node.tree.delete_node(node)
          end
        end

        if !path.meta_info['modified_at'].kind_of?(Time)
          @website.logger.debug do
            "Meta information 'modified_at' set to current time in <#{path}> since its value #{path.meta_info['modified_at'].inspect} was of type #{path.meta_info['modified_at'].class}"
          end
          path.meta_info['modified_at'] = Time.now
        end

        node = node_class(path).new(parent, path.cn, dest_path, path.meta_info.dup)
        node.node_info[:path] = path
        node.node_info[:path_handler] = self

        yield(node) if block_given?
        node
      end
      protected :create_node

      # Return the parent node for the given +path+.
      def parent_node(path)
        parent_alcn = path.meta_info['parent_alcn'] ||
          (path.parent_path == '' ? '' : Webgen::Path.new(path.parent_path).alcn)
        if !(parent = @website.tree[parent_alcn])
          raise Webgen::NodeCreationError.new("The needed parent node <#{parent_alcn}> does not exist")
        end
        parent
      end
      protected :parent_node

      # Construct the destination path for the given +path+ and +parent+ node.
      #
      # See the user documentation for how a destination path is constructed and which configuration
      # options are used!
      #
      # First it is checked if a node with the constructed destination path already exists. If it
      # exists, the language part is forced to be in the destination path and the resulting
      # destination path is returned.
      def dest_path(parent, path)
        dpath = construct_dest_path(parent, path, false)
        if (node = node_exists?(path, dpath)) && node.lang != path.meta_info['lang']
          dpath = construct_dest_path(parent, path, true)
        end
        dpath
      end
      protected :dest_path

      DEST_PATH_SEGMENTS = /<.*?>|\(.*?\)/ # :nodoc:
      DEST_PATH_PARENT_SEGMENTS = /<parent(-?\d+)(?:..(-?\d+))?>/

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
                          elsif @website.config['path_handler.lang_code_in_dest_path'] == 'except_default'
                            @website.config['website.lang'] != path.meta_info['lang']
                          else
                            @website.config['path_handler.lang_code_in_dest_path']
                          end
          use_version_part = if @website.config['path_handler.version_in_dest_path'] == 'except_default'
                               path.meta_info['version'] != 'default'
                             else
                               @website.config['path_handler.version_in_dest_path']
                             end

          replace_segment = lambda do |match|
            case match
            when DEST_PATH_PARENT_SEGMENTS
              nr1 = adjust_index($1.to_i)
              (nr2 = adjust_index($2.to_i)) if $2
              [parent_segments[nr2 ? nr1..nr2 : nr1]].flatten.compact.join('/')
            when "<parent>"
              parent.dest_path
            when "<basename>"
              path.basename
            when "<ext>"
              path.ext.empty? ? '' : '.' << path.ext
            when "<lang>"
              use_lang_part ? path.meta_info['lang'] : ''
            when "<version>"
              use_version_part ? path.meta_info['version'] : ''
            when /<(year|month|day)>/
              ctime = path.meta_info['created_at']
              if !ctime.kind_of?(Time)
                raise Webgen::NodeCreationError.new("Invalid meta info 'created_at', needed for destination path creation")
              end
              ctime.send($1).to_s.rjust(2, '0')
            when /\((.*)\)/
              inner = $1
              replaced = inner.gsub(DEST_PATH_SEGMENTS, &replace_segment)
              removed = inner.gsub(DEST_PATH_SEGMENTS, "")
              replaced == removed ? '' : replaced
            else
              raise Webgen::NodeCreationError.new("Unknown destination path segment name: #{match}")
            end
          end
          dest_path.gsub!(DEST_PATH_SEGMENTS, &replace_segment)
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

      # Check if the node alcn or the destination path, which would be created by #create_node for
      # the given paths, exists.
      def node_exists?(path, dest_path)
        @website.tree[path.alcn] || (!path.meta_info['no_output'] && @website.tree.node(dest_path, :dest_path))
      end
      protected :node_exists?

      # Retrieve the node class that should be used for the given path.
      def node_class(path)
        if String === (klass = path.meta_info['node_class'])
          Webgen::Utils.const_for_name(klass) rescue Node
        elsif String === (klass = path.meta_info['base_node_class'])
          Webgen::Utils.const_for_name(klass) rescue Node
        else
          Node
        end
      end
      protected :node_class

    end

  end

end
