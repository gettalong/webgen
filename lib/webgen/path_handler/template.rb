# -*- encoding: utf-8 -*-

require 'webgen/path_handler/base'
require 'webgen/path_handler/page_utils'

module Webgen
  class PathHandler

    # Path handler for handling template files in Webgen Page Format.
    class Template

      include Base
      include PageUtils

      # Create a template node for +path+.
      def create_nodes(path, blocks)
        create_node(path) do |node|
          set_blocks(node, blocks)
        end
      end

      # Return the template chain for +node+
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
      def template_chain(node, lang = node.lang)
        cached_template = (@website.cache.volatile[[node.alcn, :templates]] ||= {})
        if cached_template.has_key?(lang)
          template_node = cached_template[lang]
        elsif node['template'].kind_of?(String)
          template_node = node.resolve!(node['template'], lang)
          if template_node.nil?
            @website.logger.warn { "Specified template '#{node['template']}' for <#{node}> not found, using default template!" }
            template_node = default_template(node.parent, lang)
          end
          cached_template[lang] = template_node
        elsif node.meta_info.has_key?('template') && node['template'].nil?
          template_node = cached_template[lang] = nil
        else
          @website.logger.debug { "Using default template in language '#{lang}' for <#{node}>" }
          template_node = default_template(node.parent, lang)
          if template_node == node && !node.parent.is_root?
            template_node = default_template(node.parent.parent, lang)
          end
          cached_template[lang] = template_node
        end

        if template_node.nil?
          []
        else
          (template_node == node ? [] : template_chain(template_node, lang) + [template_node])
        end
      end

      # Return the default template for the directory node +dir+ and language +lang+. If the
      # template node is not found, the parent directories are searched.
      def default_template(dir, lang)
        template = dir.resolve(@website.config['path_handler.template.default_template'], lang)
        if template.nil?
          if dir.is_root?
            @website.logger.warn { "No default template in root directory found!" }
          else
            template = default_template(dir.parent, lang)
          end
        end
        template
      end

    end

  end
end
