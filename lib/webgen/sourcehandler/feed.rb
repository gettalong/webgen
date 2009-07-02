# -*- encoding: utf-8 -*-

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

    # Create atom and/or rss feed files from +path+.
    def create_node(path)
      page = page_from_path(path)
      path.meta_info['link'] ||= path.parent_path

      if MANDATORY_INFOS.any? {|t| path.meta_info[t].nil?}
        raise Webgen::NodeCreationError.new("At least one of #{MANDATORY_INFOS.join('/')} is missing",
                                            self.class.name, path)
      end

      create_feed_node = lambda do |type|
        path.ext = type
        super(path) do |node|
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
      website.cache[[:sourcehandler_feed, node.node_info[:src]]] = feed_entries(node).map {|n| n.alcn}

      block_name = node.node_info[:feed_type] + '_template'
      if node.node_info[:feed].blocks.has_key?(block_name)
        node.node_info[:feed].blocks[block_name].render(Webgen::Context.new(:chain => [node])).content
      else
        chain = [node.resolve("/templates/#{node.node_info[:feed_type]}_feed.template"), node]
        node.node_info[:used_nodes] << chain.first.alcn
        chain.first.node_info[:page].blocks['content'].render(Webgen::Context.new(:chain => chain)).content
      end
    end

    # Return the entries for the feed +node+.
    def feed_entries(node)
      nr_items = (node['number_of_entries'].to_i == 0 ? 10 : node['number_of_entries'].to_i)
      patterns = [node['entries']].flatten.map {|pat| Webgen::Path.make_absolute(node.parent.alcn, pat)}

      node.tree.node_access[:alcn].values.
        select {|node| patterns.any? {|pat| node =~ pat} && node.node_info[:page]}.
        sort {|a,b| a['modified_at'] <=> b['modified_at']}[0, nr_items]
    end

    # Return the feed link URL for the feed +node+.
    def feed_link(node)
      Webgen::Node.url(File.join(node['site_url'], node.tree[node['link']].path), false)
    end

    # Return the content of an +entry+ of the feed +node+.
    def entry_content(node, entry)
      entry.node_info[:page].blocks[node['content_block_name'] || 'content'].render(Webgen::Context.new(:chain => [entry])).content
    end

    #######
    private
    #######

    # Check if the any of the nodes used by this feed +node+ have changed and then mark the node as
    # dirty.
    def node_changed?(node)
      return if node.node_info[:processor] != self.class.name
      entries = node.feed_entries
      node.flag(:dirty) if entries.map {|n| n.alcn } != website.cache[[:sourcehandler_feed, node.node_info[:src]]] ||
        entries.any? {|n| n.changed?}
    end

  end

end
