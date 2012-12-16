# -*- encoding: utf-8 -*-

require 'webgen/path_handler/base'
require 'webgen/page'
require 'webgen/error'

module Webgen
  class PathHandler

    # This module should be used by path handlers that need to work with paths in Webgen Page Format.
    #
    # Note that this modules provides an implementation for the #parse_meta_info! method. If you
    # also include the Base module, make sure that you include it before this module! Also make sure
    # to override this method if you need custom behaviour!
    module PageUtils

      # Custom Node class that provides easy access to the blocks of the parsed page file and
      # methods for rendering a block.
      class Node < Webgen::PathHandler::Base::Node

        # Return the blocks (see PageUtils#parse_as_page!) for this node.
        def blocks
          node_info[:blocks]
        end

        # Render the block +name+ of this node using the provided Context object.
        #
        # Uses the content processors specified for the block via the +blocks+ meta information key if
        # the +pipeline+ parameter is not set.
        #
        # Returns the given context with the rendered content.
        def render_block(name, context, pipeline = nil)
          unless blocks.has_key?(name)
            raise Webgen::RenderError.new("No block named '#{name}' found", nil, context.dest_node.alcn, alcn)
          end

          content_processor = context.website.ext.content_processor
          context.website.ext.item_tracker.add(context.dest_node, :node_content, alcn)

          context.content = blocks[name].dup
          context[:block_name] = name
          pipeline ||= ((self['blocks'] || {})[name] || {})['pipeline'] ||
            ((self['blocks'] || {})['defaults'] || {})['pipeline'] ||
            []
          content_processor.normalize_pipeline(pipeline).each do |processor|
            content_processor.call(processor, context)
          end
          context[:block_name] = nil
          context
        end

        # Return the template chain for this node.
        #
        # When invoked directly, the +lang+ parameter should not be used. This parameter is necessary
        # for the recursive invocation of the method so that the correct templates are used. Consider
        # the following path hierarchy:
        #
        #   /default.en.template
        #   /default.de.template
        #   /custom.template
        #   /index.de.page                  template: custom.template
        #   /index.en.page                  template: custom.template
        #
        # The template chains for index.en.page and index.de.page are therefore
        #
        #   /default.en.template → /custom.template
        #   /default.de.template → /custom.template
        #
        # This means that the /custom.template needs to reference different templates depending on the
        # language.
        def template_chain(lang = @lang)
          cached_template = (tree.website.cache.volatile[[alcn, :templates]] ||= {})
          if cached_template.has_key?(lang)
            template_node = cached_template[lang]
          elsif self['template'].kind_of?(String)
            template_node = resolve(self['template'], lang, true)
            if template_node.nil?
              tree.website.logger.warn do
                ["Template '#{self['template']}' for <#{self}> not found, using default template!",
                 'Fix the value of the meta information \'template\' for <#{self}>']
              end
              template_node = default_template(parent, lang)
            end
            cached_template[lang] = template_node
          elsif meta_info.has_key?('template') && self['template'].nil?
            template_node = cached_template[lang] = nil
          else
            tree.website.logger.debug { "Using default template in language '#{lang}' for <#{self}>" }
            template_node = default_template(parent, lang)
            if template_node == self && !parent.is_root?
              template_node = default_template(parent.parent, lang)
            end
            cached_template[lang] = template_node
          end

          if template_node.nil?
            []
          else
            (template_node == self ? [] : template_node.template_chain(lang) + [template_node])
          end
        end

        # Return the default template for the directory node +dir+ and language +lang+.
        #
        # If the template node is not found, the parent directories are searched.
        def default_template(dir, lang)
          default_template_name = tree.website.config['path_handler.default_template']
          template = dir.resolve(default_template_name, lang)
          if template.nil?
            if dir.is_root?
              tree.website.logger.warn do
                ["Default template '#{default_template_name}' not found in root directory!",
                 'Provide a </#{default_template_name}> to fix this warning.']
              end
            else
              template = default_template(dir.parent, lang)
            end
          end
          template
        end
        protected :default_template

      end


      def create_node(path, node_klass = Node) #:nodoc:
        super
      end

      # Calls #parse_as_page! to update the meta information hash of +path+. Returns the found
      # blocks which will be passed as second parameter to the #create_nodes method.
      def parse_meta_info!(path)
        parse_as_page!(path)
      end

      # Assume that the content of the given +path+ is in Webgen Page Format and parse it. Updates
      # 'path.meta_info' with the meta info from the page and returns the content blocks.
      def parse_as_page!(path)
        begin
          page = Webgen::Page.from_data(path.data)
        rescue Webgen::Page::FormatError => e
          raise Webgen::Error.new("Error reading source path: #{e.message}", nil, path)
        end
        blocks = page.meta_info.delete('blocks') || {}
        path.meta_info.merge!(page.meta_info)
        blocks.each {|key, val| ((path.meta_info['blocks'] ||= {})[key] ||= {}).merge!(val)}
        page.blocks
      end
      private :parse_as_page!

      # Set the blocks (see #parse_as_page!) for the node.
      def set_blocks(node, blocks)
        node.node_info[:blocks] = blocks
      end
      private :set_blocks

    end

  end
end
