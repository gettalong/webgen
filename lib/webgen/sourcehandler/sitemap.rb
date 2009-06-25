# -*- encoding: utf-8 -*-

require 'uri'
require 'time'

module Webgen::SourceHandler

  # Source handler for creating an XML sitemap based on the specification of http://sitemaps.org.
  #
  # Uses Webgen::Common::Sitemap to generate the needed sitemap tree and to check if a sitemap has
  # changed.
  class Sitemap

    include Webgen::WebsiteAccess
    include Base

    # Create an XML sitemap from +path+.
    def create_node(path)
      page = page_from_path(path)
      path.ext = 'xml'
      raise "Needed information site_url missing for sitemap <#{path}>" if path.meta_info['site_url'].nil?
      super(path) do |node|
        node.node_info[:sitemap] = page
      end
    end

    # Return the rendered feed represented by +node+.
    def content(node)
      if node.node_info[:sitemap].blocks.has_key?('template')
        node.node_info[:sitemap].blocks['template'].render(Webgen::Context.new(:chain => [node])).content
      else
        chain = [node.resolve("/templates/sitemap.template"), node]
        node.node_info[:used_nodes] << chain.first.alcn
        chain.first.node_info[:page].blocks['content'].render(Webgen::Context.new(:chain => chain)).content
      end
    end

    # Return the alcns of the sitemap +node+ as a flat list.
    def alcns(node)
      website.blackboard.invoke(:create_sitemap, node, node.lang, options_for_node(node)).to_lcn_list.flatten
    end

    #######
    private
    #######

    # Return a hash with the sitemap-creation-options set on the +node+.
    def options_for_node(node)
      options = {}
      node.meta_info.each {|k,v| options[k] = v if k =~ /\./}
      options
    end

  end

end
