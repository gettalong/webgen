require 'webgen/websiteaccess'
require 'webgen/loggable'
require 'webgen/page'

module Webgen::SourceHandler

  # This module should be included in every source handler as it provides the default methods for
  # creating nodes.
  #
  # = Implementing Source Handlers
  #
  # A source handler is a webgen extension that processes source paths to create nodes and that
  # provides the rendered content of these nodes. The nodes are later written to the output
  # location. This can range from simply copying a path from the source to the output location to
  # generating a whole set of nodes from one input path!
  #
  # The paths that are handled by a source handler are specified via path patterns (see
  # below). During a webgen run the #create_node method for each source paths that matches a
  # specified path pattern is called. And when it is time to write out the node, the the #content
  # method is called to retrieve the rendered content.
  #
  # A source handler must not take any parameters on initialization and when this module is not
  # mixed in, the methods #create_node and #content need to be defined. Also, a source handler does
  # not need to reside under the Webgen::SourceHandler namespace but all shipped ones do.
  #
  # This base class provides useful default implementations of methods that are used by nearly all
  # source handler class:
  # * #create_node
  # * #node_exists?
  #
  # It also provides other utility methods:
  # * #page_from_path
  # * #content
  #
  # = Nodes Created for Paths
  #
  # The main functions of a source handler class are to create one or more nodes for a source path
  # and to provide the content of these nodes. To achieve this, certain information needs to be set
  # on a node. If you use the methods provided by this base class, you don't need to set them
  # explicitly because this is done by the provided methods.
  #
  # <tt>node_info[:processor]</tt>:: Has to be set to the class name of the source handler. This is
  #                                  used by the Node class: all unknown method calls are forwarded
  #                                  to the node processor.
  # <tt>node_info[:src]</tt>:: Has to be set to the string version of the path that lead to the
  #                            creation of the node.
  # <tt>node_info[:creation_path]</tt>:: Has to be set to the string version of the path that is
  #                                      used to create the path.
  # <tt>meta_info['no_output']</tt>:: Has to be set to +true+ on nodes that are used during a
  #                                   webgen run but do not produce an output file.
  # <tt>meta_info['modified_at']</tt>:: Is automatically set to the current time if not already set
  #                                     correctly (ie. if not a Time object).
  #
  # Note: The difference between +:src+ and +:creation_path+ is that a creation path need not have
  # an existing source path representation. For example, fragments created from a page source path
  # have a different +:creation_path+ which includes the fragment part.
  #
  # Additional information that is used only for processing purposes should be stored in the
  # #node_info hash of a node as the #meta_info hash is reserved for real node meta information and
  # should not be changed once the node is created.
  #
  # = Path Patterns and Invocation order
  #
  # Path patterns define which paths are handled by a specific source handler. These patterns are
  # specified in the <tt>sourcehandler.patterns</tt> configuration hash as a mapping from the source
  # handler class name to an array of path patterns. The patterns need to have a format that
  # <tt>Dir.glob</tt> can handle. You can use the configuration helper +patterns+ to set this (is
  # shown in the example below).
  #
  # Specifying a path pattern does not mean that webgen uses the source handler. One also needs to
  # provide an entry in the configuration value <tt>sourcehandler.invoke</tt>. This is a hash that
  # maps the invocation rank (a number) to an array of source handler class names. The lower the
  # invocation rank the earlier the specified source handlers are used.
  #
  # The default invocation ranks are:
  # 1:: Early. Normally there is no need to use this rank.
  # 5:: Standard. This is the rank the normal source handler should use.
  # 9:: Late. This rank should be used by source handlers that operate on/use already created nodes
  #     and need to ensure that these nodes are available.
  #
  # = Default Meta Information
  #
  # Each source handler can define default meta information that gets automatically set on the
  # source paths that are passed to the #create_node method.
  #
  # The default meta information is specified in the <tt>sourcehandler.default_meta_info</tt>
  # configuration hash as a mapping from the source handler class name to the meta information
  # hash.
  #
  # = Sample Source Handler Class
  #
  # Following is a simple source handler class example which copies paths from the source to
  # the output location modifying the extension:
  #
  #   class SimpleCopy
  #
  #     include Webgen::SourceHandler::Base
  #
  #     def create_node(parent, path)
  #       path.ext += '.copied'
  #       super(parent, path)
  #     end
  #
  #     def content(node)
  #       website.blackboard.invoke(:source_paths)[node.node_info[:src]].io
  #     end
  #
  #   end
  #
  #   WebsiteAccess.website.config.patterns('SimpleCopy' => ['**/*.jpg', '**/*.png'])
  #   WebsiteAccess.website.config.sourcehandler.invoke[5] << 'SimpleCopy'
  #
  module Base

    # This module is used for defining all methods that can be used for creating output paths.
    #
    # All public methods of this module are considered to be output path creation methods and must
    # have the following parameters:
    # +parent+:: the parent node
    # +path+:: the path for which the output name should be created
    # +use_lang_part+:: controls whether the output path name has to include the language part
    module OutputPathHelpers

      # Default method for creating an output path for +parent+ and source +path+.
      #
      # The automatically set parameter +style+ (which uses the meta information +output_path_style+
      # from the path's meta information hash) defines how the output name should be built (more
      # information about this in the user documentation).
      def standard_output_path(parent, path, use_lang_part, style = path.meta_info['output_path_style'])
        result = style.collect do |part|
          case part
          when String  then part
          when :lang   then use_lang_part ? path.meta_info['lang'] : ''
          when :ext    then path.ext.empty? ? '' : '.' + path.ext
          when :parent then temp = parent; temp = temp.parent while temp.is_fragment?; temp.path
          when :year, :month, :day
            ctime = path.meta_info['created_at']
            if !ctime.kind_of?(Time)
              raise "Invalid meta info 'created_at' for #{path}, needed because of used output path style"
            end
            ctime.send(part).to_s.rjust(2, '0')
          when Symbol  then path.send(part)
          when Array   then part.include?(:lang) && !use_lang_part ? '' : standard_output_path(parent, path, use_lang_part, part)
          else ''
          end
        end
        result.join('')
      end

    end

    include Webgen::Loggable
    include OutputPathHelpers

    # Construct the output name for the given +path+ and +parent+. First it is checked if a node
    # with the constructed output name already exists. If it exists, the language part is forced to
    # be in the output name and the resulting output name is returned.
    def output_path(parent, path)
      method = path.meta_info['output_path'] + '_output_path'
      use_lang_part = if path.meta_info['lang'].nil? # unlocalized files never get a lang in the filename!
                        false
                      else
                        Webgen::WebsiteAccess.website.config['sourcehandler.default_lang_in_output_path'] ||
                          Webgen::WebsiteAccess.website.config['website.lang'] != path.meta_info['lang']
                      end
      if OutputPathHelpers.public_instance_methods(false).include?(method)
        name = send(method, parent, path, use_lang_part)
        name += '/'  if path.path =~ /\/$/ && name !~ /\/$/
        if (node = node_exists?(parent, path, name)) && node.lang == path.meta_info['lang']
          name = node.path
        elsif node
          name = send(method, parent, path, (path.meta_info['lang'].nil? ? false : true))
          name += '/'  if path.path =~ /\/$/ && name !~ /\/$/
        end
        name
      else
        raise "Unknown method for creating output path: #{method}"
      end
    end

    # Check if the node alcn and output path which would be created by #create_node exists. The
    # +output_path+ to check for can individually be set.
    def node_exists?(parent, path, output_path = self.output_path(parent, path))
      parent.tree[Webgen::Node.absolute_name(parent, path.lcn, :alcn)] || (!path.meta_info['no_output'] && parent.tree[output_path, :path])
    end

    # Create a node under +parent+ from +path+ if it does not already exists or needs to be
    # re-initialized. The found node or the newly created node is returned afterwards. +nil+ is
    # returned if no node can be created (e.g. when <tt>path.meta_info['draft']</tt> is set). Some
    # additional node information like <tt>:src</tt> and <tt>:processor</tt> is set and the meta
    # information is checked for validness. The created/re-initialized node is yielded if a block is
    # given.
    def create_node(parent, path, output_path = self.output_path(parent, path))
      return nil if path.meta_info['draft']
      node = node_exists?(parent, path, output_path)
      if node && (node.node_info[:src] != path.source_path || node.node_info[:processor] != self.class.name)
        log(:warn) { "Node already exists: source = #{path.source_path} | path = #{node.path} | alcn = #{node.absolute_lcn}"}
        return node
      elsif !node
        node = Webgen::Node.new(parent, output_path, path.cn, path.meta_info)
      elsif node.flagged(:reinit)
        node.reinit(output_path, path.meta_info)
      else
        return node
      end
      node['modified_at'] = Time.now unless node['modified_at'].kind_of?(Time)
      node.node_info[:src] = path.source_path
      node.node_info[:creation_path] = path.path
      node.node_info[:processor] = self.class.name
      yield(node) if block_given?
      node
    end

    # Return the content of the given +node+. This default +content+ method just returns +nil+.
    def content(node)
      nil
    end

    # Utility method for creating a Webgen::Page object from the +path+. Also updates
    # <tt>path.meta_info</tt> with the meta info from the page.
    def page_from_path(path)
      begin
        page = Webgen::Page.from_data(path.io.data, path.meta_info)
      rescue Webgen::WebgenPageFormatError => e
        raise "Error reading source path <#{path}>: #{e.message}"
      end
      path.meta_info = page.meta_info
      page
    end

  end

end
