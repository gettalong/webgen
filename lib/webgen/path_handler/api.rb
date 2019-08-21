# -*- encoding: utf-8 -*-

require 'time'
require 'ostruct'
require 'shellwords'
require 'webgen/path_handler/base'
require 'webgen/path_handler/page_utils'
require 'webgen/context'
require 'webgen/path'
require 'webgen/content_processor/r_doc'

module Webgen
  class PathHandler

    # Path handler for Ruby API documentation via rdoc.
    class Api

      include Base
      include PageUtils

      # The mandatory meta info keys that need to be set on an api path.
      MANDATORY_INFOS = %W[rdoc_options]

      # Create the feed nodes.
      def create_nodes(path, blocks)
        if MANDATORY_INFOS.any? {|t| path.meta_info[t].nil?}
          raise Webgen::NodeCreationError.new("At least one of #{MANDATORY_INFOS.join('/')} is missing",
                                              "path_handler.api", path)
        end

        path['api_name'] ||= path.basename
        path['dir_name'] ||= path.basename

        cache_dir = @website.tmpdir(File.join('path_handler.api', path['api_name']))
        rdoc = rdoc_object(path['rdoc_options'], cache_dir)
        output_flag_file = rdoc.output_flag_file(cache_dir)

        dir_node = create_directory(path, Webgen::Path.new(path.parent_path + path['dir_name'] + '/'), false)

        api = OpenStruct.new
        api.directory = dir_node
        api.class_nodes = {}
        api.file_nodes = {}

        rdoc.store.all_classes_and_modules.sort.each do |klass|
          adapt_rdoc_class(path, klass)
          klass_node = create_page_node_for_class(path, dir_node, klass, output_flag_file)
          api.class_nodes[klass.full_name] = klass_node
          klass_node.node_info[:api] = api
          create_fragment_nodes_for_constants(path, klass_node, klass)
          create_fragment_nodes_for_attributes(path, klass_node, klass)
          create_fragment_nodes_for_methods(path, klass_node, klass)
        end

        rdoc.store.all_files.sort.each do |file|
          next unless file.text?
          file_node = create_page_node_for_file(path, dir_node, file, output_flag_file)
          api.file_nodes[file.full_name] = file_node
          file_node.node_info[:api] = api
        end

        nil
      end

      # Create a directory for the path, applying needed meta information from the api path.
      #
      # Also creates the parent directories when necessary.
      def create_directory(api_path, path, set_proxy_path = true)
        if (dir = @website.tree[path.alcn])
          return dir
        end

        parent_path = Webgen::Path.new(path.parent_path)
        if !@website.tree[parent_path.alcn]
          create_directory(api_path, parent_path)
        end

        path['modified_at'] = api_path['modified_at']
        path['handler'] = 'directory'
        path['proxy_path'] ||= "../#{path.basename}.html" if set_proxy_path
        @website.ext.path_handler.create_secondary_nodes(path).first
      end
      private :create_directory

      # Create the RDoc instance and use it for generating the API data.
      #
      # If possible, cached data available under +cache_dir+ is used.
      def rdoc_object(options, cache_dir)
        start_time = Time.now

        rdoc = RDoc::RDoc.new
        rdoc.options = rdoc_options(options)
        rdoc.store = rdoc_store(rdoc.options, cache_dir)

        rdoc.exclude = rdoc.options.exclude
        rdoc.last_modified.replace(rdoc.setup_output_dir(cache_dir, false))

        if !(rdoc.parse_files(rdoc.options.files)).empty?
          rdoc.store.complete(rdoc.options.visibility)
          rdoc.store.save
          rdoc.update_output_dir(cache_dir, start_time, rdoc.last_modified)
        end
        rdoc.store.load_all

        # We need a dummy generator with some methods
        rdoc.generator = Object.new
        def (rdoc.generator).class_dir; nil; end
        def (rdoc.generator).file_dir; nil; end

        rdoc
      end
      protected :rdoc_object

      # Return a fully initialized RDoc::Options object.
      #
      # Some of the user specified options may not be used if they would interfere with this class'
      # job.
      def rdoc_options(user_options)
        user_options = Shellwords.split(user_options) if user_options.kind_of?(String)
        options = RDoc::Options.new
        options.parse(user_options)
        options.verbosity = 0
        options.dry_run = false
        options.update_output_dir = true
        options.force_output = false
        options.finish
        options
      end
      protected :rdoc_options

      # Return a fully initialized RDoc::Store object.
      def rdoc_store(options, cache_dir)
        store = RDoc::Store.new(cache_dir)
        store.encoding = options.encoding
        store.dry_run = options.dry_run
        store.main = options.main_page
        store.title = options.title
        store.load_cache
        store
      end
      protected :rdoc_store

      # Adapt a RDoc class/module object to provide a different output path depending on the
      # output_structure meta information of the API path.
      def adapt_rdoc_class(api_path, klass)
        case api_path['output_structure']
        when 'hierarchical'
          api_path['use_proxy_path'] = false
          def klass.http_url(prefix)
            if classes_and_modules.size > 0
              super(prefix).sub(/\.html/, '/index.html')
            else
              super(prefix)
            end
          end
        else
          api_path['use_proxy_path'] = true
        end
      end
      protected :adapt_rdoc_class

      # Create a page node for the given class +klass+ and return it.
      #
      # A link definition entry for the class is also created.
      def create_page_node_for_class(api_path, dir_node, klass, output_flag_file)
        klass_path_str = klass.http_url(dir_node.alcn)

        create_directory(api_path, Webgen::Path.new(File.dirname(klass_path_str) + '/'), api_path['use_proxy_path'])

        path = Webgen::Path.new(klass_path_str, 'handler' => 'page', 'modified_at' => api_path['modified_at'],
                                'title' => "#{klass.full_name}", 'api_class_name' => klass.full_name,
                                'api_name' => api_path['api_name'], 'template' => api_path['api_template'])
        node = @website.ext.path_handler.create_secondary_nodes(path).first

        node.node_info[:rdoc_object] = klass
        @website.ext.item_tracker.add(node, :file, output_flag_file)
        add_link_definition(api_path, klass.full_name, node.alcn, klass.full_name)

        node
      end
      protected :create_page_node_for_class

      # Creates fragment nodes for constants under the "Constants" fragment.
      def create_fragment_nodes_for_constants(api_path, klass_node, klass)
        return if klass.constants.none? {|const| const.display? }
        constants_url = "#{klass_node.alcn}#Constants"
        path = Webgen::Path.new(constants_url,
                                {'handler' => 'copy', 'modified_at' => api_path['modified_at'],
                                 'pipeline' => [], 'no_output' => true, 'title' => "Constants"})
        const_node = @website.ext.path_handler.create_secondary_nodes(path).first
        klass.constants.sort_by(&:name).each do |const|
          create_fragment_node_for_constant(api_path, const_node, const)
        end
      end
      protected :create_fragment_nodes_for_constants

      # Create a fragment node for the given constant.
      #
      # A link definition entry for the method is also created.
      def create_fragment_node_for_constant(api_path, parent_node, constant)
        constant_url = "#{parent_node.alcn.sub(/#.*$/, '')}##{constant.name}"
        path = Webgen::Path.new(constant_url,
                                {'handler' => 'copy', 'modified_at' => api_path['modified_at'],
                                 'parent_alcn' => parent_node.alcn,
                                 'pipeline' => [], 'no_output' => true, 'title' => constant.name})
        @website.ext.path_handler.create_secondary_nodes(path)
        add_link_definition(api_path, constant.full_name, constant_url, constant.full_name)
      end
      protected :create_fragment_node_for_constant

      # Creates fragment nodes for attributes under the "Attributes" fragment.
      def create_fragment_nodes_for_attributes(api_path, parent_node, klass)
        return if klass.attributes.none? {|attr| attr.display? }
        attributes_url = "#{parent_node.alcn}#Attributes"
        path = Webgen::Path.new(attributes_url,
                                {'handler' => 'copy', 'modified_at' => api_path['modified_at'],
                                  'parent_alcn' => parent_node.alcn,
                                 'pipeline' => [], 'no_output' => true, 'title' => "Attributes"})
        attr_node = @website.ext.path_handler.create_secondary_nodes(path).first
        klass.attributes.sort_by(&:name).each do |attribute|
          create_fragment_node_for_method(api_path, attr_node, attribute)
        end
      end
      protected :create_fragment_nodes_for_attributes

      # Creates fragment nodes for methods under the "Class Methods" or "Instance Methods"
      # fragments.
      def create_fragment_nodes_for_methods(api_path, klass_node, klass)
        ["Class", "Instance"].each do |type|
          method_list = klass.send("#{type.downcase}_method_list")
          next if method_list.empty?
          meth_url = "#{klass_node.alcn}##{type}-Methods"
          path = Webgen::Path.new(meth_url,
                                  {'handler' => 'copy', 'modified_at' => api_path['modified_at'],
                                    'pipeline' => [], 'no_output' => true,
                                    'title' => "#{type} Methods"})
          meth_node = @website.ext.path_handler.create_secondary_nodes(path).first
          method_list.sort_by(&:name).each do |method|
            create_fragment_node_for_method(api_path, meth_node, method)
          end
        end
      end
      protected :create_fragment_nodes_for_attributes

      # Create a fragment node for the given method.
      #
      # A link definition entry for the method is also created.
      def create_fragment_node_for_method(api_path, parent_node, method)
        method_url = "#{parent_node.alcn.sub(/#.*$/, '')}##{method.aref}"
        path = Webgen::Path.new(method_url,
                                {'handler' => 'copy', 'modified_at' => api_path['modified_at'],
                                  'parent_alcn' => parent_node.alcn,
                                  'pipeline' => [], 'no_output' => true, 'title' => method.name})
        @website.ext.path_handler.create_secondary_nodes(path)
        add_link_definition(api_path, method.full_name, method_url, method.full_name)
      end
      protected :create_fragment_node_for_method

      # Create a page node for the given file and return it.
      def create_page_node_for_file(api_path, dir_node, file, output_flag_file)
        file_path_str = file.http_url(dir_node.alcn)

        create_directory(api_path, Webgen::Path.new(File.dirname(file_path_str) + '/'))

        path = Webgen::Path.new(file_path_str, 'handler' => 'page', 'modified_at' => api_path['modified_at'],
                                'title' => "File #{file.full_name}", 'api_file_name' => file.full_name,
                                'api_name' => api_path['api_name'], 'template' => api_path['api_template'])
        node = @website.ext.path_handler.create_secondary_nodes(path).first

        node.node_info[:rdoc_object] = file
        @website.ext.item_tracker.add(node, :file, output_flag_file)

        node
      end
      protected :create_page_node_for_file

      # Add a link definition for the given node.
      def add_link_definition(api_path, link_name, url, title)
        link = if api_path['prefix_link_defs']
                 "#{api_path['api_name']}:#{link_name}"
               else
                 link_name
               end
        @website.ext.link_definitions[link] = [url, title]
      end
      protected :add_link_definition

    end

  end
end
