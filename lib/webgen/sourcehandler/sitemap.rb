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

    # Create an XML sitemap from +parent+ and +path+.
    def create_node(parent, path)
      page_from_path(path)
      path.ext = 'xml'
      raise "Needed information site_url missing for sitemap <#{path}>" if path.meta_info['site_url'].nil?
      super(parent, path)
    end

    # Return the rendered feed represented by +node+.
    def content(node)
      require 'builder'
      list = website.blackboard.invoke(:create_sitemap, node, node.lang, options_for_node(node)).to_lcn_list.flatten
      sitemap = ::Builder::XmlMarkup.new(:indent => 2)
      sitemap.instruct!(:xml, :version => '1.0', :encoding => 'UTF-8')
      sitemap.urlset(:xmlns => "http://www.sitemaps.org/schemas/sitemap/0.9") do
        list.each do |alcn|
          item = node.tree[alcn]
          sitemap.url do |url|
            sitemap.loc(URI.escape(File.join(node['site_url'], item.path)))
            sitemap.lastmod(item['modified_at'].iso8601)
            changefreq = item['change_freq'] || node['default_change_freq']
            sitemap.changefreq(changefreq) if changefreq
            priority = item['priority'] || node['default_priority']
            sitemap.priority(priority) if priority
          end
        end
      end
      sitemap.target!
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
