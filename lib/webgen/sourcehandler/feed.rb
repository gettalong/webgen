module Webgen::SourceHandler

  # Source handler for creating atom and/or rss feeds.
  class Feed

    include Webgen::WebsiteAccess
    include Base

    # The mandatory keys that need to be set in a feed file.
    MANDATORY_INFOS = %W[site_url author entries]

    def initialize # :nodoc:
      website.blackboard.add_listener(:node_changed?, method(:node_changed?))
    end

    # Create atom and/or rss feed files from +parent+ and +path+.
    def create_node(parent, path)
      page = page_from_path(path)
      path.meta_info['link'] ||= parent.absolute_lcn

      if MANDATORY_INFOS.any? {|t| path.meta_info[t].nil?}
        raise "One of #{MANDATORY_INFOS.join('/')} information missing for feed <#{path}>"
      end

      create_feed_node = lambda do |type|
        path.ext = type
        super(parent, path) do |node|
          node.node_info[:feed] = page
          node.node_info[:feed_type] = type
        end
      end

      nodes = []
      nodes << create_feed_node['atom'] if path.meta_info['atom']
      nodes << create_feed_node['rss'] if path.meta_info['rss']

      nodes
    end

    # Return the rendered feed represented by +node+.
    def content(node)
      website.cache[[:sourcehandler_feed, node.node_info[:src]]] = feed_entries(node).map {|n| n.absolute_lcn}
      block_name = node.node_info[:feed_type] + '_template'
      if node.node_info[:feed].blocks.has_key?(block_name)
        node.node_info[:feed].blocks[block_name].
          render(Webgen::ContentProcessor::Context.new(:chain => [node])).content
      else
        feed = (website.cache.volatile[:sourcehandler_feed] ||= {})[node.node_info[:src]] ||= build_feed_for(node)
        feed.feed_type = node.node_info[:feed_type]
        feed.build_xml
      end
    end

    # Helper method for returning the entries for the feed node +node+.
    def feed_entries(node)
      nr_items = (node['number_of_entries'].to_i == 0 ? 10 : node['number_of_entries'].to_i)
      patterns = [node['entries']].flatten.map {|pat| Pathname.new(pat =~ /^\// ? pat : File.join(node.parent.absolute_lcn, pat)).cleanpath.to_s}

      node.tree.node_access[:alcn].values.
        select {|node| patterns.any? {|pat| node =~ pat} && node.node_info[:page]}.
        sort {|a,b| a['modified_at'] <=> b['modified_at']}.
        reverse[0, nr_items]
    end

    #######
    private
    #######

    # Return the populated FeedTools::Feed object for +node+.
    def build_feed_for(node)
      require 'feed_tools'
      require 'time'

      site_url = node['site_url']

      feed = FeedTools::Feed.new
      feed.title = node['title']
      feed.description = node['description']
      feed.author = node['author']
      feed.author.url = node['author_url']
      feed.base_uri = site_url
      feed.link = File.join(site_url, node.tree[node['link']].path)
      feed.id = feed.link

      feed.published = (node['created_at'].kind_of?(Time) ? node['created_at'] : Time.now)
      feed.updated = Time.now
      feed.generator = 'webgen - Webgen::SourceHandler::Feed'
      feed.icon = File.join(site_url, node.tree[node['icon']].path) if node['icon']

      node.feed_entries.each do |entry|
        item = FeedTools::FeedItem.new
        item.title = entry['title']
        item.link = File.join(site_url, entry.path)
        item.content = entry.node_info[:page].blocks['content'].render(Webgen::ContentProcessor::Context.new(:chain => [entry])).content
        item.updated = entry['modified_at']
        item.published = entry['created_at'] if entry['created_at'].kind_of?(Time)
        if entry['author']
          item.author = entry['author']
          item.author.url = entry['author_url']
        end
        item.id = item.link
        feed << item
      end
      feed
    end

    # Check if the +node+ has meta information from any meta info node and if so, if the meta info
    # node in question has changed.
    def node_changed?(node)
      return if node.node_info[:processor] != self.class.name
      entries = node.feed_entries
      node.dirty = true if entries.map {|n| n.absolute_lcn } != website.cache[[:sourcehandler_feed, node.node_info[:src]]] ||
        entries.any? {|n| n.changed?}
    end

  end

end
