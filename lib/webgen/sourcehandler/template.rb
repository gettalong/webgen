module Webgen::SourceHandler

  # Source handler for handling template files in Webgen Page Format.
  class Template

    include Webgen::WebsiteAccess
    include Webgen::Loggable
    include Base

    # Create a template node in +parent+ for +path+.
    def create_node(parent, path)
      page = page_from_path(path)
      super(parent, path) do |node|
        node.node_info[:page] = page
      end
    end

    # Return the template chain for +node+.
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
        template_node = default_template(node.parent, lang)
        if template_node == node && !node.parent.is_root?
          template_node = default_template(node.parent.parent, lang)
        end
        cached_template[lang] = template_node
      end

      if template_node.nil?
        []
      else
        (template_node == node ? [] : templates_for_node(template_node, lang) + [template_node])
      end
    end

    # Return the default template for the directory node +dir+. If the template node is not found,
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
