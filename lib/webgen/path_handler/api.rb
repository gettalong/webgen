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
          klass_node = create_page_node_for_class(path, dir_node, klass, output_flag_file)
          api.class_nodes[klass.full_name] = klass_node
          klass_node.node_info[:api] = api
          klass.each_method {|method| create_fragment_node_for_method(path, klass_node, method)}
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

      # Create a page node for the given class +klass+ and return it.
      #
      # A link definition entry for the class is also created.
      def create_page_node_for_class(api_path, dir_node, klass, output_flag_file)
        klass_path_str = klass.http_url(dir_node.alcn)

        create_directory(api_path, Webgen::Path.new(File.dirname(klass_path_str) + '/'))

        path = Webgen::Path.new(klass_path_str, 'handler' => 'page', 'modified_at' => api_path['modified_at'],
                                'title' => "#{klass.type} #{klass.full_name}", 'api_class_name' => klass.full_name,
                                'api_name' => api_path['api_name'], 'template' => api_path['api_template'])
        node = @website.ext.path_handler.create_secondary_nodes(path).first

        node.node_info[:rdoc_object] = klass
        @website.ext.item_tracker.add(node, :file, output_flag_file)
        add_link_definition(api_path, klass.full_name, node.alcn, klass.full_name)

        node
      end
      protected :create_page_node_for_class

      # Create a fragment node for the given method.
      #
      # A link definition entry for the method is also created.
      def create_fragment_node_for_method(api_path, klass_node, method)
        method_url = "#{klass_node.alcn}##{method.aref}"
        path = Webgen::Path.new(method_url,
                                {'handler' => 'copy', 'modified_at' => api_path['modified_at'],
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
