require 'webgen/websiteaccess'
require 'webgen/loggable'
require 'webgen/page'

module Webgen::SourceHandler

  # Source handler for handling template files in Webgen Page Format.
  class Template

    include Webgen::WebsiteAccess
    include Webgen::Loggable
    include Base

    def create_node(parent, path)
      #TODO: eventually create helper method for creating a page from a path
      begin
        page = Webgen::Page.from_data(path.io.read, path.meta_info)
      rescue Webgen::WebgenPageFormatError => e
        raise "Error reading source path <#{path}>: #{e.message}"
      end
      path.meta_info = page.meta_info
      super(parent, path) do |node|
        node.node_info[:page] = page
        #TODO: maybe the following is still needed, check later
        #node.node_info[:no_output_file] = true
      end
    end

    # Returns the template chain for +node+.
    def templates_for_node(node, lang = node.lang)
      cached_template = (website.cache.volatile[[node.absolute_lcn, :templates]] ||= {})
      if cached_template[lang]
        template_node = cached_template[lang]
      elsif node['template'].kind_of?(String)
        template_node = node.resolve(node['template'], lang)
        if template_node.nil?
          log(:warn) { "Specified template '#{node['template']}' for <#{node.absolute_lcn}> not found, using default template!" }
          template_node = default_template(node.parent, lang)
        end
        cached_template[lang] = template_node
      elsif node.meta_info.has_key?('template') && node['template'].nil?
        template_node = cached_template[lang] = nil
      else
        log(:info) { "Using default template in language '#{lang}' for <#{node.absolute_lcn}>" }
        template_node = cached_template[lang] = default_template(node.parent, lang)
      end

      if template_node.nil?
        []
      else
        (template_node == node ? [] : templates_for_node(template_node, lang) + [template_node])
      end
    end

    # Returns the default template for the directory node +dir+. If the template node is not found,
    # the parent directories are searched.
    def default_template(dir_node, lang)
      template_node = dir_node.resolve(website.config['sourcehandler.template.default_template'], lang)
      if template_node.nil?
        if dir_node.is_root?
          log(:warn) { "No default template in root directory found!" }
        else
          template_node = default_template(dir_node.parent, lang)
        end
      end
      template_node
    end

  end

end
