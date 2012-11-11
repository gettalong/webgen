# -*- encoding: utf-8 -*-

require 'webgen/content_processor'
require 'webgen/path'
webgen_require 'sass'

module Webgen
  class ContentProcessor

    # Processes content in Sass markup (used for writing CSS files).
    module Sass

      # Custom importer for Sass to load files from the file system but resolves absolute paths from
      # the given root directory and not from the filesystem root!
      class FileSystemImporter < ::Sass::Importers::Filesystem

        def find_real_file(dir, name, options = {}) #:nodoc:
          for (f,s) in possible_files(remove_root(name))
            if full_path = Dir["#{dir}/#{f}"].first
              full_path.gsub!(REDUNDANT_DIRECTORY,File::SEPARATOR)
              return full_path, s
            end
          end
          nil
        end

      end

      # Custom importer for Sass to load files by resolving them in the node tree.
      class NodeTreeImporter < ::Sass::Importers::Base

        # Creates a new importer that imports files from the node tree relative to the given node alcn.
        def initialize(website, alcn)
          @website = website
          @alcn = alcn
        end

        # @see Base#find_relative
        def find_relative(name, base, options)
          _find(base, name, options)
        end

        # @see Base#find
        def find(name, options)
          _find(@alcn, name, options)
        end

        def mtime(name, options) #:nodoc:
          node = resolve_node(@alcn, name)
          node['modified_at'] if node
        end

        def key(name, options) #:nodoc:
          ["webgen:", name]
        end

        def to_s #:nodoc:
          "webgen: #{@alcn}"
        end

        #######
        private
        #######

        # Find the @import-ed name under the given base filename.
        #
        # Returns a Sass::Engine object if found or +nil+ otherwise.
        def _find(base, name, options)
          node, syntax = resolve_node(base, name)
          return unless node

          options[:syntax] = syntax
          options[:filename] = node.alcn
          options[:importer] = self
          ::Sass::Engine.new(node.node_info[:path].data, options)
        end

        # Resolve the path using the given base filename.
        #
        # Returns [node, syntax] if a node was found or nil otherwise
        def resolve_node(base, path)
          possible_filenames(path).each do |filename, syntax|
            node = @website.tree.resolve_node(Webgen::Path.append(base, filename), nil)
            return [node, syntax] if node
          end
          nil
        end

        # Return an array of all possible (filename, syntax) pairs for the given path.
        def possible_filenames(path)
          dirname, basename = File.split(path)
          basename, ext = basename.scan(/^(.*?)(?:\.(sass|scss))?$/).first
          (ext.nil? ? %w{sass scss} : [ext]).map do |ext|
            [["#{dirname}/_#{basename}.#{ext}", ext.to_sym], ["#{dirname}/#{basename}.#{ext}", ext.to_sym]]
          end.flatten(1)
        end

      end

      module ::Sass::Script::Functions

        # Return the correct relative path for the given path.
        def relocatable(path)
          assert_type(path, :String)
          context = options[:webgen_context]
          path = path.value

          dest_node = context.website.tree[options[:filename]].resolve(path, context.dest_node.lang, true)
          if dest_node
            context.website.ext.item_tracker.add(context.dest_node, :node_meta_info, dest_node.alcn)
            result = context.dest_node.route_to(dest_node)
          else
            result = path
          end
          ::Sass::Script::String.new("url(\"#{result}\")")
        end
        declare :relocatable, [:string]

      end

      # Convert the content in +sass+ markup to CSS.
      def self.call(context)
        context.content = ::Sass::Engine.new(context.content, default_options(context)).render
        context
      rescue ::Sass::SyntaxError => e
        raise Webgen::RenderError.new(e, self.class.name, context.dest_node, nil, (e.sass_line if e.sass_line))
      end

      def self.default_options(context) # :nodoc:
        opts = context.website.config['content_processor.sass.options']
        load_paths = context.website.ext.sass_load_paths + [NodeTreeImporter.new(context.website, '/')]
        opts.merge({
                     :filename => context.ref_node.alcn,
                     :syntax => :sass,
                     :cache_store => ::Sass::CacheStores::Filesystem.new(context.website.tmpdir('sass')),
                     :filesystem_importer => FileSystemImporter,
                     :load_paths => load_paths,
                     :webgen_context => context
                   })
      end

    end

  end
end
